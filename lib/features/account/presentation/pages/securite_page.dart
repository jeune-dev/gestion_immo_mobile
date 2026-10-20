import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/changer_mot_de_passe_page.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/double_authentification_page.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/sessions_page.dart';

/// Sécurité du compte : mot de passe, double authentification, appareils connectés.
class SecuritePage extends StatelessWidget {
  const SecuritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mfa = context.select((AuthBloc b) =>
        b.state.compte?.utilisateur.doubleAuthentificationActive ?? false);
    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Changer de mot de passe'),
                  subtitle:
                      const Text('Les autres appareils seront déconnectés'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ouvrir(context, const ChangerMotDePassePage()),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Double authentification'),
                  subtitle: Text(mfa
                      ? 'Activée'
                      : 'Un code à 6 chiffres en plus du mot de passe'),
                  trailing: Pastille(mfa ? 'Activée' : 'Désactivée',
                      ton: mfa ? TonStatut.succes : TonStatut.neutre),
                  onTap: () =>
                      ouvrir(context, const DoubleAuthentificationPage()),
                ),
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: const Text('Appareils connectés'),
                  subtitle: const Text('Déconnexion à distance'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ouvrir(context, const SessionsPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
