import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session_cubit.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import 'auth_cadre.dart';

/// Changement de mot de passe : obligatoire si le mot de passe est provisoire
/// ([force]), sinon depuis le profil. Les autres appareils sont déconnectés.
class ChangerMotDePasseScreen extends StatefulWidget {
  const ChangerMotDePasseScreen({super.key, this.force = false});
  final bool force;

  @override
  State<ChangerMotDePasseScreen> createState() => _ChangerMotDePasseScreenState();
}

class _ChangerMotDePasseScreenState extends State<ChangerMotDePasseScreen> {
  final _form = GlobalKey<FormState>();
  final _actuel = TextEditingController();
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
      await context.read<SessionCubit>().changerMotDePasse(_actuel.text, _mdp.text);
      if (!mounted) return;
      afficherSucces(context, 'Mot de passe modifié. Les autres appareils ont été déconnectés.');
      if (!widget.force) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _erreur = e.messageComplet);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCadre(
      retour: !widget.force,
      titre: widget.force ? 'Choisissez votre mot de passe' : 'Changer de mot de passe',
      sousTitre: widget.force ? 'Votre mot de passe actuel est provisoire : remplacez-le pour continuer.' : null,
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_erreur != null) ...[Encadre(_erreur!, ton: TonStatut.danger), const SizedBox(height: AppTheme.espaceLg)],
            ChampMotDePasse(controleur: _actuel, libelle: 'Mot de passe actuel'),
            const SizedBox(height: AppTheme.espaceLg),
            ChampMotDePasse(controleur: _mdp, libelle: 'Nouveau mot de passe', nouveau: true, validator: validerMotDePasse),
            const SizedBox(height: AppTheme.espaceLg),
            ChampMotDePasse(
              controleur: _confirmation,
              libelle: 'Confirmation',
              validator: (v) => v != _mdp.text ? 'Les mots de passe diffèrent' : null,
            ),
            const SizedBox(height: AppTheme.espaceXl),
            FilledButton(onPressed: _envoi ? null : _valider, child: const Text('Enregistrer')),
            if (widget.force)
              TextButton(onPressed: () => context.read<SessionCubit>().deconnecter(), child: const Text('Se déconnecter')),
          ]),
        ),
      ],
    );
  }
}
