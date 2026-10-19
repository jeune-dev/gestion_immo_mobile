import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session_cubit.dart';
import '../../core/widgets/base.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import 'auth_cadre.dart';

/// Activation du compte locataire (§ 5 option B) : code d'invitation à 8 chiffres
/// reçu du propriétaire, téléphone et mot de passe.
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _telephone = TextEditingController();
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  Future<void> _valider() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await context.read<SessionCubit>().activerLocataire({
        'code': _code.text.trim(),
        'phone': _telephone.text.trim(),
        'password': _mdp.text,
        'password_confirmation': _confirmation.text,
      });
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
      titre: 'Activer mon compte locataire',
      sousTitre: "Saisissez le code d'invitation reçu de votre propriétaire et le numéro de téléphone qu'il a enregistré.",
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_erreur != null) ...[Encadre(_erreur!, ton: TonStatut.danger), const SizedBox(height: AppTheme.espaceLg)],
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(labelText: "Code d'invitation"),
              validator: (v) => RegExp(r'^\d{8}$').hasMatch((v ?? '').trim()) ? null : '8 chiffres',
            ),
            TextFormField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(labelText: 'Téléphone', hintText: '77 123 45 67'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: AppTheme.espaceLg),
            ChampMotDePasse(controleur: _mdp, libelle: 'Choisissez un mot de passe', nouveau: true, validator: validerMotDePasse),
            const SizedBox(height: AppTheme.espaceLg),
            ChampMotDePasse(
              controleur: _confirmation,
              libelle: 'Confirmation',
              validator: (v) => v != _mdp.text ? 'Les mots de passe diffèrent' : null,
            ),
            const SizedBox(height: AppTheme.espaceXl),
            FilledButton(onPressed: _envoi ? null : _valider, child: const Text('Activer mon compte')),
          ]),
        ),
      ],
    );
  }
}
