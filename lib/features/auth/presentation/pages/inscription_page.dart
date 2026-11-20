import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/demander_code_inscription.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/verifier_code_inscription.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/erreur_auth.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/parcours_kit.dart';
import 'package:gestion_immo_mobile/injection_container.dart';

/// Les cinq étapes de l'inscription d'un propriétaire (§ 5).
enum _Etape { nom, contact, motDePasse, verification, activite }

/// Inscription d'un propriétaire, une étape à la fois.
///
/// L'écran unique d'avant demandait huit champs d'un coup : on ne savait pas
/// où l'on en était, et la moindre erreur renvoyait en haut d'un long
/// formulaire. Ici chaque étape tient dans l'écran, avec sa progression.
///
/// L'ORDRE compte : l'adresse est vérifiée (étape 4) AVANT que le compte
/// n'existe. Un compte créé porte donc une adresse qui fonctionne — et une
/// inscription abandonnée ne laisse rien derrière elle.
class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  static const _libelles = [
    'Vous',
    'Contact',
    'Sécurité',
    'Vérification',
    'Activité',
  ];

  /// Secondes avant de pouvoir redemander un code.
  static const _attenteRenvoi = 30;

  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  final _societe = TextEditingController();
  final _ville = TextEditingController();

  final _formNom = GlobalKey<FormState>();
  final _formContact = GlobalKey<FormState>();
  final _formMotDePasse = GlobalKey<FormState>();

  _Etape _etape = _Etape.nom;
  bool _enCours = false;
  String? _erreur;
  String? _info;
  String _code = '';

  /// Preuve que l'adresse a été vérifiée, remise à l'étape 4.
  String? _jetonEmail;

  int _secondesRestantes = 0;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    effacerErreurAuth(context);
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    for (final c in [
      _prenom,
      _nom,
      _telephone,
      _email,
      _mdp,
      _societe,
      _ville,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _adresse => _email.text.trim().toLowerCase();

  void _lancerAttente() {
    _minuteur?.cancel();
    setState(() => _secondesRestantes = _attenteRenvoi);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondesRestantes--);
      if (_secondesRestantes <= 0) t.cancel();
    });
  }

  void _retour() {
    if (_etape == _Etape.nom) return context.pop();
    // Revenir sur l'adresse après l'envoi du code annulerait la vérification :
    // on repart alors de l'étape du contact, et un nouveau code sera demandé.
    setState(() {
      _erreur = null;
      _info = null;
      _etape = _Etape.values[_etape.index - 1];
      if (_etape == _Etape.contact) _jetonEmail = null;
    });
  }

  /// Le formulaire de l'étape en cours est-il valide ?
  bool _valide() => switch (_etape) {
    _Etape.nom => _formNom.currentState?.validate() ?? false,
    _Etape.contact => _formContact.currentState?.validate() ?? false,
    _Etape.motDePasse => _formMotDePasse.currentState?.validate() ?? false,
    _ => true,
  };

  Future<void> _suivant() async {
    if (_enCours || !_valide()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _erreur = null;
      _info = null;
    });

    switch (_etape) {
      case _Etape.nom:
        setState(() => _etape = _Etape.contact);
      case _Etape.contact:
        setState(() => _etape = _Etape.motDePasse);
      case _Etape.motDePasse:
        await _envoyerCode(premier: true);
      case _Etape.verification:
        await _verifierCode();
      case _Etape.activite:
        _creerLeCompte();
    }
  }

  /// Étape 3 → 4 : demande du code, puis l'écran de saisie.
  Future<void> _envoyerCode({bool premier = false}) async {
    setState(() => _enCours = true);
    final r = await sl<DemanderCodeInscription>()(
      _adresse,
      prenom: _prenom.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _enCours = false;
      r.fold(
        (echec) {
          _erreur = echec.messageComplet;
          // L'adresse est déjà prise : la corriger se fait à l'étape 2.
          if (echec.code == 'COMPTE_EXISTANT') _etape = _Etape.contact;
        },
        (_) {
          _etape = _Etape.verification;
          if (!premier) _info = 'Un nouveau code vient de partir.';
        },
      );
    });
    if (r.isRight()) _lancerAttente();
  }

  Future<void> _verifierCode() async {
    if (_code.length < 6) {
      return setState(() => _erreur = 'Saisissez les 6 chiffres du code.');
    }
    setState(() => _enCours = true);
    final r = await sl<VerifierCodeInscription>()(_adresse, _code);
    if (!mounted) return;
    setState(() {
      _enCours = false;
      r.fold((echec) => _erreur = echec.messageComplet, (jeton) {
        _jetonEmail = jeton;
        _etape = _Etape.activite;
      });
    });
  }

  void _creerLeCompte() {
    context.read<AuthBloc>().add(
      InscriptionDemandee({
        'first_name': _prenom.text.trim(),
        'last_name': _nom.text.trim(),
        'phone': IdentifiantValidator.telephone(_telephone.text).valeur!,
        'email': _adresse,
        'password': _mdp.text,
        // Le serveur exige la confirmation ; l'œil du champ permet de relire
        // ce qu'on a tapé, un second champ identique n'apporterait rien.
        'password_confirmation': _mdp.text,
        if (_societe.text.trim().isNotEmpty)
          'company_name': _societe.text.trim(),
        if (_ville.text.trim().isNotEmpty) 'city': _ville.text.trim(),
        if (_jetonEmail != null) 'email_token': _jetonEmail,
      }),
    );
  }

  (IconData, String, String) get _entete => switch (_etape) {
    _Etape.nom => (
      Icons.person_outline_rounded,
      'Votre nom',
      'Il apparaîtra sur vos quittances.',
    ),
    _Etape.contact => (
      Icons.alternate_email_rounded,
      'Vos coordonnées',
      'Un code vous sera envoyé par e-mail.',
    ),
    _Etape.motDePasse => (
      Icons.lock_outline_rounded,
      'Mot de passe',
      'Protégez votre compte.',
    ),
    _Etape.verification => (
      Icons.mark_email_unread_outlined,
      'Vérifiez votre e-mail',
      'Code envoyé à $_adresse',
    ),
    _Etape.activite => (
      Icons.business_center_outlined,
      'Votre activité',
      'Pour vos quittances et vos documents.',
    ),
  };

  String get _libelleBouton => switch (_etape) {
    _Etape.motDePasse => 'Recevoir mon code',
    _Etape.verification => 'Vérifier',
    _Etape.activite => 'Terminer',
    _ => 'Continuer',
  };

  @override
  Widget build(BuildContext context) {
    final (icone, titre, sousTitre) = _entete;
    // La dernière étape crée le compte : c'est l'AuthBloc qui travaille.
    final envoiCompte = context.select((AuthBloc b) => b.state.enCours);
    final echecCompte = context.select((AuthBloc b) => b.state.failure);
    final occupe = _enCours || envoiCompte;

    return PopScope(
      canPop: _etape == _Etape.nom,
      onPopInvokedWithResult: (aPoppe, _) {
        if (!aPoppe) _retour();
      },
      child: CadreParcours(
        icone: icone,
        titre: titre,
        sousTitre: sousTitre,
        etape: _etape.index + 1,
        etapes: _libelles,
        onRetour: _retour,
        carte: [
          BandeauErreur(_erreur ?? _messageEchec(echecCompte)),
          if (_info != null) ...[
            _BandeauInfo(_info!),
            const SizedBox(height: AppTheme.espaceLg),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _contenu(),
          ),
          const SizedBox(height: AppTheme.espaceXl),
          BoutonParcours(
            libelle: _libelleBouton,
            enCours: occupe,
            icone: _etape == _Etape.activite ? null : Icons.arrow_forward,
            onPressed: _suivant,
          ),
          if (_etape == _Etape.verification) ...[
            const SizedBox(height: AppTheme.espaceMd),
            Center(child: _lienRenvoi()),
          ],
        ],
        apres: [
          if (_etape == _Etape.nom)
            LienConnexion(onTap: () => context.go(AppRouter.connexion)),
          if (_etape == _Etape.verification)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.espaceMd),
              child: Text(
                'Pensez à vérifier vos courriers indésirables.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.texteSecondaire,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// L'échec de création du compte ne s'affiche qu'à l'étape où il se produit.
  String? _messageEchec(Failure? echec) =>
      _etape == _Etape.activite ? echec?.messageComplet : null;

  Widget _lienRenvoi() {
    if (_secondesRestantes > 0) {
      return Text(
        'Renvoyer dans $_secondesRestantes s',
        style: TextStyle(fontSize: 13, color: context.palette.texteSecondaire),
      );
    }
    return TextButton(
      onPressed: _enCours ? null : () => _envoyerCode(),
      child: const Text('Renvoyer le code'),
    );
  }

  Widget _contenu() => switch (_etape) {
    _Etape.nom => Form(
      key: _formNom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Champ(
            libelle: 'Prénom',
            exemple: 'Awa',
            controleur: _prenom,
            icone: Icons.person_outline,
            majuscules: true,
            autofill: const [AutofillHints.givenName],
            validator: (v) => IdentifiantValidator.nom(v).erreurFormulaire,
          ),
          const SizedBox(height: AppTheme.espaceMd),
          _Champ(
            libelle: 'Nom',
            exemple: 'Diop',
            controleur: _nom,
            icone: Icons.person_outline,
            majuscules: true,
            autofill: const [AutofillHints.familyName],
            validator: (v) => IdentifiantValidator.nom(v).erreurFormulaire,
          ),
        ],
      ),
    ),
    _Etape.contact => Form(
      key: _formContact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Champ(
            libelle: 'E-mail',
            exemple: 'exemple@email.com',
            controleur: _email,
            icone: Icons.mail_outline,
            clavier: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            validator: (v) =>
                IdentifiantValidator.email(v, obligatoire: true).erreurFormulaire,
          ),
          const SizedBox(height: AppTheme.espaceMd),
          _Champ(
            libelle: 'Téléphone',
            exemple: '77 123 45 67',
            controleur: _telephone,
            icone: Icons.phone_outlined,
            clavier: TextInputType.phone,
            autofill: const [AutofillHints.telephoneNumber],
            filtres: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s+().-]'))],
            validator: (v) => IdentifiantValidator.telephone(
              v,
              obligatoire: true,
            ).erreurFormulaire,
          ),
        ],
      ),
    ),
    _Etape.motDePasse => Form(
      key: _formMotDePasse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LibelleChamp('Mot de passe'),
          ChampMotDePasse(
            controleur: _mdp,
            nouveau: true,
            indication: 'Choisissez un mot de passe',
            validator: (v) =>
                IdentifiantValidator.motDePasse(v).erreurFormulaire,
          ),
          const SizedBox(height: AppTheme.espaceXs),
          ReglesMotDePasse(controleur: _mdp),
        ],
      ),
    ),
    _Etape.verification => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LibelleChamp('Code à 6 chiffres'),
        CasesCode(
          onChange: (c) => _code = c,
          onComplet: (_) => _verifierCode(),
        ),
      ],
    ),
    _Etape.activite => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Champ(
          libelle: 'Société',
          mention: 'facultatif',
          exemple: 'Diop Immobilier',
          controleur: _societe,
          icone: Icons.business_outlined,
          majuscules: true,
          longueurMax: 150,
        ),
        const SizedBox(height: AppTheme.espaceMd),
        _Champ(
          libelle: 'Ville',
          mention: 'facultatif',
          exemple: 'Dakar',
          controleur: _ville,
          icone: Icons.location_on_outlined,
          majuscules: true,
          longueurMax: 100,
        ),
      ],
    ),
  };
}

/// Message vert d'une étape (code renvoyé…).
class _BandeauInfo extends StatelessWidget {
  final String message;
  const _BandeauInfo(this.message);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppTheme.espaceMd),
      decoration: BoxDecoration(
        color: p.succesFond,
        borderRadius: BorderRadius.circular(AppTheme.rayon),
        border: Border.all(color: p.succes.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: p.succes),
          const SizedBox(width: AppTheme.espaceSm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: p.succes),
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de saisie avec son libellé au-dessus et un exemple visible dedans.
class _Champ extends StatelessWidget {
  final String libelle;
  final String? mention;
  final String exemple;
  final IconData? icone;
  final TextEditingController controleur;
  final TextInputType? clavier;
  final bool majuscules;
  final List<String>? autofill;
  final List<TextInputFormatter>? filtres;
  final int? longueurMax;
  final String? Function(String?)? validator;

  const _Champ({
    required this.libelle,
    required this.exemple,
    required this.controleur,
    this.mention,
    this.icone,
    this.clavier,
    this.majuscules = false,
    this.autofill,
    this.filtres,
    this.longueurMax,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LibelleChamp(libelle, mention: mention),
      TextFormField(
        controller: controleur,
        keyboardType: clavier,
        textInputAction: TextInputAction.next,
        autofillHints: autofill,
        autocorrect: false,
        inputFormatters: filtres,
        maxLength: longueurMax,
        buildCounter:
            (_, {required currentLength, required isFocused, maxLength}) =>
                null,
        textCapitalization: majuscules
            ? TextCapitalization.words
            : TextCapitalization.none,
        decoration: InputDecoration(
          hintText: exemple,
          errorMaxLines: 3,
          prefixIcon: icone == null ? null : Icon(icone),
        ),
        validator: validator,
      ),
    ],
  );
}
