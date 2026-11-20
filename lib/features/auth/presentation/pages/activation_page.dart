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
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/parcours_kit.dart';

/// Activation du compte locataire (§ 5 option B), en deux étapes : le code
/// d'invitation à 8 chiffres et le téléphone enregistré par le propriétaire,
/// puis le mot de passe.
///
/// Le locataire ne s'inscrit pas : son espace existe déjà, créé par son
/// propriétaire. Il n'y a donc ni e-mail à vérifier ni abonnement — le code de
/// l'invitation tient lieu de preuve.
///
/// Le serveur ne contrôle le code qu'au moment de l'activation complète (une
/// route qui dirait « ce code existe » se ferait moissonner) : un code faux
/// n'apparaît donc qu'à la fin, et ramène à la première étape.
class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  static const _libelles = ['Votre invitation', 'Sécurité'];

  final _formInvitation = GlobalKey<FormState>();
  final _formMotDePasse = GlobalKey<FormState>();
  final _telephone = TextEditingController();
  final _mdp = TextEditingController();

  String _code = '';
  int _etape = 0;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    effacerErreurAuth(context);
  }

  @override
  void dispose() {
    _telephone.dispose();
    _mdp.dispose();
    super.dispose();
  }

  void _retour() {
    if (_etape == 0) return context.pop();
    setState(() {
      _erreur = null;
      _etape = 0;
    });
  }

  void _suivant() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_etape == 0) {
      if (_code.length < 8) {
        return setState(
          () => _erreur = "Saisissez les 8 chiffres du code d'invitation.",
        );
      }
      if (!(_formInvitation.currentState?.validate() ?? false)) return;
      return setState(() {
        _erreur = null;
        _etape = 1;
      });
    }
    if (!(_formMotDePasse.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      ActivationDemandee({
        'code': _code,
        'phone': IdentifiantValidator.telephone(_telephone.text).valeur!,
        'password': _mdp.text,
        'password_confirmation': _mdp.text,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enCours = context.select((AuthBloc b) => b.state.enCours);
    // Invitation refusée : la correction se fait à la première étape.
    final echec = context.select((AuthBloc b) => b.state.failure);
    if (echec?.code == 'INVITATION_INVALIDE' && _etape == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _etape == 1) setState(() => _etape = 0);
      });
    }

    return PopScope(
      canPop: _etape == 0,
      onPopInvokedWithResult: (aPoppe, _) {
        if (!aPoppe) _retour();
      },
      child: CadreParcours(
        icone: _etape == 0 ? Icons.vpn_key_rounded : Icons.lock_outline_rounded,
        titre: _etape == 0 ? 'Activer mon espace' : 'Votre mot de passe',
        sousTitre: _etape == 0
            ? 'Le code vient de votre propriétaire.'
            : 'Il vous servira à vous connecter.',
        etape: _etape + 1,
        etapes: _libelles,
        onRetour: _retour,
        carte: [
          BandeauErreur(_erreur),
          const ErreurAuth(),
          if (_etape == 0)
            Form(
              key: _formInvitation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LibelleChamp("Code d'invitation"),
                  CasesCode(
                    longueur: 8,
                    onChange: (c) => _code = c,
                  ),
                  const SizedBox(height: AppTheme.espaceMd),
                  const LibelleChamp('Téléphone'),
                  TextFormField(
                    controller: _telephone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s+().-]')),
                    ],
                    decoration: const InputDecoration(
                      hintText: "Celui qu'il a enregistré",
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => IdentifiantValidator.telephone(
                      v,
                      obligatoire: true,
                    ).erreurFormulaire,
                  ),
                ],
              ),
            )
          else
            Form(
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
          const SizedBox(height: AppTheme.espaceXl),
          BoutonParcours(
            libelle: _etape == 0 ? 'Continuer' : 'Entrer dans mon espace',
            enCours: enCours,
            icone: _etape == 0 ? Icons.arrow_forward : null,
            onPressed: _suivant,
          ),
        ],
        apres: [
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.espaceMd),
            child: Text(
              _etape == 0
                  ? 'Pas de code ? Demandez-le à votre propriétaire.'
                  : 'Vous pourrez le changer depuis votre profil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.texteSecondaire),
            ),
          ),
          if (_etape == 0)
            LienConnexion(onTap: () => context.go(AppRouter.connexion)),
        ],
      ),
    );
  }
}
