import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/changer_mot_de_passe_page.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/double_authentification_page.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/sessions_page.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Sécurité du compte : mot de passe, double authentification, appareils connectés.
class SecuritePage extends StatelessWidget {
  const SecuritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mfa = context.select(
      (AuthBloc b) =>
          b.state.compte?.utilisateur.doubleAuthentificationActive ?? false,
    );
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Sécurité'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.espaceLg),
        children: [
          Encadre(
            mfa
                ? 'Votre compte est bien protégé : la double authentification est activée.'
                : 'Renforcez votre compte en activant la double authentification.',
            ton: mfa ? TonStatut.succes : TonStatut.info,
          ),
          const SizedBox(height: AppTheme.espaceXl),
          GroupeOptions(
            titre: 'Accès au compte',
            children: [
              TuileOption(
                icone: Icons.password,
                titre: 'Changer de mot de passe',
                detail: 'Les autres appareils seront déconnectés',
                onTap: () => ouvrir(context, const ChangerMotDePassePage()),
              ),
              TuileOption(
                icone: Icons.verified_user_outlined,
                titre: 'Double authentification',
                detail: 'Un code à 6 chiffres en plus du mot de passe',
                fin: Pastille(
                  mfa ? 'Activée' : 'Désactivée',
                  ton: mfa ? TonStatut.succes : TonStatut.neutre,
                ),
                onTap: () =>
                    ouvrir(context, const DoubleAuthentificationPage()),
              ),
              TuileOption(
                icone: Icons.devices_outlined,
                titre: 'Appareils connectés',
                detail: 'Voir et déconnecter à distance',
                onTap: () => ouvrir(context, const SessionsPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
