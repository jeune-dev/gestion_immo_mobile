import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/erreur_auth.dart';

/// Inscription d'un propriétaire (§ 5) : crée son espace avec la période d'essai.
class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _form = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _email = TextEditingController();
  final _societe = TextEditingController();
  final _ville = TextEditingController();
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();

  /// Après un premier envoi refusé, les messages suivent la saisie.
  bool _soumis = false;

  @override
  void initState() {
    super.initState();
    effacerErreurAuth(context);
  }

  @override
  void dispose() {
    for (final c in [
      _prenom,
      _nom,
      _telephone,
      _email,
      _societe,
      _ville,
      _mdp,
      _confirmation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _valider() {
    setState(() => _soumis = true);
    final invalides = _form.currentState!.validateGranularly();
    if (invalides.isNotEmpty) {
      Scrollable.ensureVisible(
        invalides.first.context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 200),
      );
      return;
    }
    context.read<AuthBloc>().add(
      InscriptionDemandee({
        'first_name': _prenom.text.trim(),
        'last_name': _nom.text.trim(),
        'phone': IdentifiantValidator.telephone(_telephone.text).valeur!,
        'email': _email.text.trim().toLowerCase(),
        if (_societe.text.trim().isNotEmpty)
          'company_name': _societe.text.trim(),
        if (_ville.text.trim().isNotEmpty) 'city': _ville.text.trim(),
        'password': _mdp.text,
        'password_confirmation': _confirmation.text,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCadre(
      retour: true,
      titre: 'Créer mon compte',
      sousTitre: 'Gérez vos immeubles, vos loyers et vos travaux.',
      children: [
        const _BandeauEssai(),
        const SizedBox(height: AppTheme.espaceXl),
        Form(
          key: _form,
          autovalidateMode: _soumis
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ErreurAuth(),
                const _TitreSection(numero: 1, titre: 'Votre identité'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ChampTexte(
                        libelle: 'Prénom',
                        exemple: 'Awa',
                        controleur: _prenom,
                        majuscules: true,
                        autofill: const [AutofillHints.givenName],
                        validator: (v) =>
                            IdentifiantValidator.nom(v).erreurFormulaire,
                      ),
                    ),
                    const SizedBox(width: AppTheme.espaceMd),
                    Expanded(
                      child: _ChampTexte(
                        libelle: 'Nom',
                        exemple: 'Diop',
                        controleur: _nom,
                        majuscules: true,
                        autofill: const [AutofillHints.familyName],
                        validator: (v) =>
                            IdentifiantValidator.nom(v).erreurFormulaire,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.espaceXl),
                const _TitreSection(numero: 2, titre: 'Vos coordonnées'),
                _ChampTexte(
                  libelle: 'Téléphone',
                  exemple: '77 123 45 67',
                  icone: Icons.phone_outlined,
                  controleur: _telephone,
                  clavier: TextInputType.phone,
                  autofill: const [AutofillHints.telephoneNumber],
                  filtres: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s+().-]')),
                  ],
                  validator: (v) => IdentifiantValidator.telephone(
                    v,
                    obligatoire: true,
                  ).erreurFormulaire,
                ),
                const SizedBox(height: AppTheme.espaceMd),
                _ChampTexte(
                  libelle: 'E-mail',
                  exemple: 'exemple@email.com',
                  icone: Icons.mail_outline,
                  controleur: _email,
                  clavier: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  validator: (v) => IdentifiantValidator.email(
                    v,
                    obligatoire: true,
                  ).erreurFormulaire,
                ),
                const SizedBox(height: AppTheme.espaceXl),
                const _TitreSection(numero: 3, titre: 'Votre activité'),
                _ChampTexte(
                  libelle: 'Société',
                  mention: 'facultatif',
                  exemple: 'Nom de votre société',
                  icone: Icons.business_outlined,
                  controleur: _societe,
                  majuscules: true,
                  longueurMax: 150,
                ),
                const SizedBox(height: AppTheme.espaceMd),
                _ChampTexte(
                  libelle: 'Ville',
                  mention: 'facultatif',
                  exemple: 'Dakar',
                  icone: Icons.location_on_outlined,
                  controleur: _ville,
                  majuscules: true,
                  longueurMax: 100,
                ),
                const SizedBox(height: AppTheme.espaceXl),
                const _TitreSection(numero: 4, titre: 'Votre mot de passe'),
                const LibelleChamp('Mot de passe'),
                ChampMotDePasse(
                  controleur: _mdp,
                  nouveau: true,
                  indication: 'Choisissez un mot de passe',
                  validator: (v) =>
                      IdentifiantValidator.motDePasse(v).erreurFormulaire,
                ),
                const SizedBox(height: AppTheme.espaceSm),
                _ReglesMotDePasse(controleur: _mdp),
                const SizedBox(height: AppTheme.espaceMd),
                const LibelleChamp('Confirmation'),
                ChampMotDePasse(
                  controleur: _confirmation,
                  indication: 'Saisissez-le à nouveau',
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Obligatoire';
                    return v != _mdp.text
                        ? 'Les mots de passe diffèrent'
                        : null;
                  },
                ),
                const SizedBox(height: AppTheme.espaceXl),
                BoutonAuth(libelle: 'Créer mon compte', onPressed: _valider),
                const SizedBox(height: AppTheme.espaceSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Déjà un compte ?',
                        style: TextStyle(
                          color: context.palette.texteSecondaire,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRouter.connexion),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Rappel de l'avantage de l'inscription, au-dessus du formulaire.
class _BandeauEssai extends StatelessWidget {
  const _BandeauEssai();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.espaceMd,
        vertical: AppTheme.espaceSm,
      ),
      decoration: BoxDecoration(
        color: p.primaireTeinte,
        borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.espaceSm),
          Expanded(
            child: Text(
              "Période d'essai offerte à la création de votre compte.",
              style: TextStyle(color: p.texte, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre d'une partie du formulaire, avec son numéro dans une pastille.
class _TitreSection extends StatelessWidget {
  final int numero;
  final String titre;
  const _TitreSection({required this.numero, required this.titre});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.espaceMd),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.espaceSm),
          Expanded(
            child: Text(
              titre,
              style: TextStyle(
                color: context.palette.texte,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de saisie avec son libellé au-dessus et un exemple visible dedans.
class _ChampTexte extends StatelessWidget {
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

  const _ChampTexte({
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
        buildCounter: (
          _, {
          required currentLength,
          required isFocused,
          maxLength,
        }) => null,
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

/// Règles du mot de passe, cochées au fil de la saisie.
class _ReglesMotDePasse extends StatelessWidget {
  final TextEditingController controleur;
  const _ReglesMotDePasse({required this.controleur});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget regle(String libelle, bool ok) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: ok ? p.succes : p.texteDiscret,
        ),
        const SizedBox(width: 4),
        Text(
          libelle,
          style: TextStyle(
            color: ok ? p.succes : p.texteSecondaire,
            fontSize: 12,
          ),
        ),
      ],
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controleur,
      builder: (_, valeur, _) {
        final s = valeur.text;
        return Wrap(
          spacing: AppTheme.espaceMd,
          runSpacing: AppTheme.espaceXs,
          children: [
            regle('8 caractères', s.length >= 8),
            regle('Une majuscule', s.contains(RegExp('[A-Z]'))),
            regle('Une minuscule', s.contains(RegExp('[a-z]'))),
            regle('Un chiffre', s.contains(RegExp(r'\d'))),
          ],
        );
      },
    );
  }
}
