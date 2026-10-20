import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
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
      bloc.add(ConnexionDemandee(
          identifiant: _identifiant.text, motDePasse: _motDePasse.text));
    } else {
      final code = _code.text.trim();
      bloc.add(
          _secours ? MfaSoumise(codeSecours: code) : MfaSoumise(code: code));
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
          : 'Gérez vos biens ou votre logement depuis votre téléphone.',
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
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.telephoneNumber
                    ],
                    decoration: const InputDecoration(
                        labelText: 'Téléphone ou e-mail',
                        hintText: '77 123 45 67'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: AppTheme.espaceLg),
                  ChampMotDePasse(controleur: _motDePasse),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () =>
                            context.push(AppRouter.motDePasseOublie),
                        child: const Text('Mot de passe oublié ?')),
                  ),
                ] else
                  TextFormField(
                    controller: _code,
                    autofocus: true,
                    keyboardType:
                        _secours ? TextInputType.text : TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: _secours ? 20 : 6,
                    decoration: InputDecoration(
                        labelText:
                            _secours ? 'Code de secours' : 'Code à 6 chiffres'),
                    validator: (v) => _secours
                        ? ((v ?? '').trim().isEmpty ? 'Obligatoire' : null)
                        : (RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
                            ? null
                            : '6 chiffres'),
                  ),
                const SizedBox(height: AppTheme.espaceMd),
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
                    child: Text(_secours
                        ? "Utiliser l'application"
                        : 'Utiliser un code de secours'),
                  ),
                  TextButton(
                      onPressed: () =>
                          context.read<AuthBloc>().add(MfaAbandonnee()),
                      child: const Text('Retour')),
                ] else ...[
                  const SizedBox(height: AppTheme.espaceXl),
                  const Divider(),
                  const SizedBox(height: AppTheme.espaceLg),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRouter.inscription),
                    icon: const Icon(Icons.apartment_outlined),
                    label:
                        const Text('Je suis propriétaire : créer mon compte'),
                  ),
                  const SizedBox(height: AppTheme.espaceSm),
                  TextButton.icon(
                    onPressed: () => context.push(AppRouter.activation),
                    icon: const Icon(Icons.key_outlined),
                    label: const Text(
                        "Je suis locataire : j'ai un code d'invitation"),
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
