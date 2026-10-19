import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import 'auth_cadre.dart';

/// Mot de passe oublié : demande d'un code à 6 chiffres puis nouveau mot de passe.
class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  final _form = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _code = TextEditingController();
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();
  bool _codeEnvoye = false;
  bool _envoi = false;
  String? _erreur;

  Future<void> _valider() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      if (!_codeEnvoye) {
        await api.post<dynamic>('/auth/mot-de-passe-oublie', body: {'identifiant': _identifiant.text.trim()}, sansJeton: true);
        setState(() => _codeEnvoye = true);
      } else {
        await api.post<dynamic>('/auth/reinitialiser-mot-de-passe',
            body: {
              'identifiant': _identifiant.text.trim(),
              'code': _code.text.trim(),
              'password': _mdp.text,
              'password_confirmation': _confirmation.text,
            },
            sansJeton: true);
        if (!mounted) return;
        afficherSucces(context, 'Mot de passe modifié : connectez-vous.');
        context.go('/connexion');
      }
    } on ApiException catch (e) {
      setState(() => _erreur = e.messageComplet);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCadre(
      retour: true,
      titre: 'Mot de passe oublié',
      sousTitre: _codeEnvoye
          ? 'Si un compte correspond, un code à 6 chiffres vient de vous être envoyé.'
          : 'Indiquez votre téléphone ou votre e-mail : nous vous envoyons un code.',
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_erreur != null) ...[Encadre(_erreur!, ton: TonStatut.danger), const SizedBox(height: AppTheme.espaceLg)],
            TextFormField(
              controller: _identifiant,
              enabled: !_codeEnvoye,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Téléphone ou e-mail'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
            ),
            if (_codeEnvoye) ...[
              const SizedBox(height: AppTheme.espaceLg),
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(labelText: 'Code reçu'),
                validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : '6 chiffres',
              ),
              ChampMotDePasse(controleur: _mdp, libelle: 'Nouveau mot de passe', nouveau: true, validator: validerMotDePasse),
              const SizedBox(height: AppTheme.espaceLg),
              ChampMotDePasse(
                controleur: _confirmation,
                libelle: 'Confirmation',
                validator: (v) => v != _mdp.text ? 'Les mots de passe diffèrent' : null,
              ),
            ],
            const SizedBox(height: AppTheme.espaceXl),
            FilledButton(
              onPressed: _envoi ? null : _valider,
              child: Text(_codeEnvoye ? 'Changer mon mot de passe' : 'Recevoir un code'),
            ),
            if (_codeEnvoye) TextButton(onPressed: () => setState(() => _codeEnvoye = false), child: const Text('Renvoyer un code')),
          ]),
        ),
      ],
    );
  }
}
