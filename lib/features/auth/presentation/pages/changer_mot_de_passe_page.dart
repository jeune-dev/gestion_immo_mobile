import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/erreur_auth.dart';

/// Changement de mot de passe : obligatoire si le mot de passe est provisoire
/// ([force]), sinon depuis le profil. Les autres appareils sont déconnectés.
class ChangerMotDePassePage extends StatefulWidget {
  final bool force;
  const ChangerMotDePassePage({super.key, this.force = false});

  @override
  State<ChangerMotDePassePage> createState() => _ChangerMotDePassePageState();
}

class _ChangerMotDePassePageState extends State<ChangerMotDePassePage> {
  final _form = GlobalKey<FormState>();
  final _actuel = TextEditingController();
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void initState() {
    super.initState();
    effacerErreurAuth(context);
  }

  void _valider() {
    if (!_form.currentState!.validate()) return;
    context
        .read<AuthBloc>()
        .add(MotDePasseChangeDemande(actuel: _actuel.text, nouveau: _mdp.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => b.succes != null && a.version != b.version,
      listener: (context, s) {
        afficherSucces(context, s.succes!);
        if (!widget.force) Navigator.of(context).pop();
      },
      child: AuthCadre(
        retour: !widget.force,
        titre: widget.force
            ? 'Choisissez votre mot de passe'
            : 'Changer de mot de passe',
        sousTitre: widget.force
            ? 'Votre mot de passe actuel est provisoire : remplacez-le pour continuer.'
            : null,
        children: [
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ErreurAuth(),
                ChampMotDePasse(
                    controleur: _actuel, libelle: 'Mot de passe actuel'),
                const SizedBox(height: AppTheme.espaceLg),
                ChampMotDePasse(
                    controleur: _mdp,
                    libelle: 'Nouveau mot de passe',
                    nouveau: true,
                    validator: (v) =>
                        IdentifiantValidator.motDePasse(v).erreurFormulaire),
                const SizedBox(height: AppTheme.espaceLg),
                ChampMotDePasse(
                  controleur: _confirmation,
                  libelle: 'Confirmation',
                  validator: (v) =>
                      v != _mdp.text ? 'Les mots de passe diffèrent' : null,
                ),
                const SizedBox(height: AppTheme.espaceXl),
                BoutonAuth(libelle: 'Enregistrer', onPressed: _valider),
                if (widget.force)
                  TextButton(
                      onPressed: () =>
                          context.read<AuthBloc>().add(DeconnexionDemandee()),
                      child: const Text('Se déconnecter')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
