import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/erreur_auth.dart';

/// Connexion (§ 5) par téléphone ou e-mail, puis code de double authentification si actif.
class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _form = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  final _code = TextEditingController();
  bool _secours = false;

  @override
  void initState() {
    super.initState();
    effacerErreurAuth(context);
  }

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    _code.dispose();
    super.dispose();
  }

  void _envoyer({required bool mfa}) {
    if (!_form.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();
    if (!mfa) {
      bloc.add(
        ConnexionDemandee(
          identifiant: _identifiant.text,
          motDePasse: _motDePasse.text,
        ),
      );
    } else {
      final code = _code.text.trim();
      bloc.add(
        _secours ? MfaSoumise(codeSecours: code) : MfaSoumise(code: code),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mfa = context.select((AuthBloc b) => b.state.mfaJeton != null);
    return AuthCadre(
      titre: mfa ? 'Code de vérification' : 'Connexion',
      sousTitre: mfa
          ? (_secours
                ? 'Saisissez un de vos codes de secours.'
                : "Saisissez le code à 6 chiffres de votre application d'authentification.")
          : 'Accédez à vos biens ou à votre logement.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ErreurAuth(),
                if (!mfa) ...[
                  TextFormField(
                    controller: _identifiant,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.telephoneNumber,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Téléphone ou e-mail',
                      hintText: '77 123 45 67',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: AppTheme.espaceMd),
                  ChampMotDePasse(controleur: _motDePasse),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRouter.motDePasseOublie),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                ] else
                  TextFormField(
                    controller: _code,
                    autofocus: true,
                    keyboardType: _secours
                        ? TextInputType.text
                        : TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: _secours ? 20 : 6,
                    decoration: InputDecoration(
                      labelText: _secours
                          ? 'Code de secours'
                          : 'Code à 6 chiffres',
                    ),
                    validator: (v) => _secours
                        ? ((v ?? '').trim().isEmpty ? 'Obligatoire' : null)
                        : IdentifiantValidator.code(
                            v,
                            longueur: 6,
                          ).erreurFormulaire,
                  ),
                const SizedBox(height: AppTheme.espaceSm),
                BoutonAuth(
                  libelle: mfa ? 'Valider' : 'Se connecter',
                  onPressed: () => _envoyer(mfa: mfa),
                ),
                if (mfa) ...[
                  TextButton(
                    onPressed: () => setState(() {
                      _secours = !_secours;
                      _code.clear();
                    }),
                    child: Text(
                      _secours
                          ? "Utiliser l'application"
                          : 'Utiliser un code de secours',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<AuthBloc>().add(MfaAbandonnee()),
                    child: const Text('Retour'),
                  ),
                ] else ...[
                  const SizedBox(height: AppTheme.espaceXl),
                  const _SeparateurAcces(),
                  const SizedBox(height: AppTheme.espaceLg),
                  _ChoixAcces(
                    icone: Icons.apartment_outlined,
                    titre: 'Je suis propriétaire',
                    detail: 'Créer mon compte',
                    onTap: () => context.push(AppRouter.inscription),
                  ),
                  const SizedBox(height: AppTheme.espaceSm),
                  _ChoixAcces(
                    icone: Icons.key_outlined,
                    titre: 'Je suis locataire',
                    detail: "J'ai un code d'invitation",
                    onTap: () => context.push(AppRouter.activation),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SeparateurAcces extends StatelessWidget {
  const _SeparateurAcces();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.espaceMd),
        child: Text(
          'Pas encore de compte ?',
          style: TextStyle(
            color: context.palette.texteSecondaire,
            fontSize: 13,
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

/// Accès pour un nouvel utilisateur : icône, profil, action.
class _ChoixAcces extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String detail;
  final VoidCallback onTap;
  const _ChoixAcces({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    final rayon = BorderRadius.circular(AppTheme.rayon);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: rayon,
        child: Ink(
          padding: const EdgeInsets.all(AppTheme.espaceMd),
          decoration: BoxDecoration(
            borderRadius: rayon,
            border: Border.all(color: p.bordure),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.primaireTeinte,
                  borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
                ),
                child: Icon(icone, color: cs.primary, size: 22),
              ),
              const SizedBox(width: AppTheme.espaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        color: p.texte,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      detail,
                      style: TextStyle(color: p.texteSecondaire, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.texteDiscret),
            ],
          ),
        ),
      ),
    );
  }
}
