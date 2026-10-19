import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session_cubit.dart';
import '../../core/widgets/base.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import 'auth_cadre.dart';

/// Connexion (§ 5) par téléphone ou e-mail, puis code de double authentification si actif.
class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _form = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  final _code = TextEditingController();
  MfaRequise? _mfa;
  bool _secours = false;
  bool _envoi = false;
  String? _erreur;

  Future<void> _connecter() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final cubit = context.read<SessionCubit>();
      if (_mfa == null) {
        final mfa = await cubit.connecter(_identifiant.text, _motDePasse.text);
        if (mfa != null) setState(() => _mfa = mfa);
      } else {
        await cubit.verifierMfa(_mfa!.jeton,
            code: _secours ? null : _code.text.trim(), codeSecours: _secours ? _code.text.trim() : null);
      }
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.messageComplet;
        if (e.code == 'JETON_MFA_INVALIDE') _mfa = null;
      });
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mfa = _mfa != null;
    return AuthCadre(
      titre: mfa ? 'Code de vérification' : 'Connexion',
      sousTitre: mfa
          ? (_secours ? 'Saisissez un de vos codes de secours.' : "Saisissez le code à 6 chiffres de votre application d'authentification.")
          : 'Gérez vos biens ou votre logement depuis votre téléphone.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_erreur != null) ...[Encadre(_erreur!, ton: TonStatut.danger), const SizedBox(height: AppTheme.espaceLg)],
              if (!mfa) ...[
                TextFormField(
                  controller: _identifiant,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username, AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(labelText: 'Téléphone ou e-mail', hintText: '77 123 45 67'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: AppTheme.espaceLg),
                ChampMotDePasse(controleur: _motDePasse),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => context.push('/mot-de-passe-oublie'), child: const Text('Mot de passe oublié ?')),
                ),
              ] else
                TextFormField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: _secours ? TextInputType.text : TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: _secours ? 20 : 6,
                  decoration: InputDecoration(labelText: _secours ? 'Code de secours' : 'Code à 6 chiffres'),
                  validator: (v) => _secours
                      ? ((v ?? '').trim().isEmpty ? 'Obligatoire' : null)
                      : (RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : '6 chiffres'),
                ),
              const SizedBox(height: AppTheme.espaceMd),
              FilledButton(
                onPressed: _envoi ? null : _connecter,
                child: _envoi
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(mfa ? 'Valider' : 'Se connecter'),
              ),
              if (mfa) ...[
                TextButton(
                  onPressed: () => setState(() {
                    _secours = !_secours;
                    _code.clear();
                  }),
                  child: Text(_secours ? "Utiliser l'application" : 'Utiliser un code de secours'),
                ),
                TextButton(onPressed: () => setState(() => _mfa = null), child: const Text('Retour')),
              ] else ...[
                const SizedBox(height: AppTheme.espaceXl),
                const Divider(),
                const SizedBox(height: AppTheme.espaceLg),
                OutlinedButton.icon(
                  onPressed: () => context.push('/inscription'),
                  icon: const Icon(Icons.apartment_outlined),
                  label: const Text('Je suis propriétaire : créer mon compte'),
                ),
                const SizedBox(height: AppTheme.espaceSm),
                TextButton.icon(
                  onPressed: () => context.push('/activation'),
                  icon: const Icon(Icons.key_outlined),
                  label: const Text("Je suis locataire : j'ai un code d'invitation"),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
