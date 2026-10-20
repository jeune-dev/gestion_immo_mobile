import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/modifier_profil.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/securite_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittances_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/consentir_whatsapp.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/caution_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/charges_locataire_page.dart';

/// Profil du locataire : caution, charges, quittances, consentement WhatsApp, sécurité.
class ProfilLocatairePage extends StatelessWidget {
  const ProfilLocatairePage({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.select((AuthBloc b) => b.state.compte?.utilisateur);
    final initiales =
        '${(u?.prenom ?? '').isNotEmpty ? u!.prenom[0] : ''}${(u?.nom ?? '').isNotEmpty ? u!.nom[0] : ''}'
            .toUpperCase();
    Widget tuile(IconData i, String t, VoidCallback onTap, {String? sous}) =>
        ListTile(
          leading: Icon(i),
          title: Text(t),
          subtitle: sous == null ? null : Text(sous),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                  radius: 28, child: Text(initiales.isEmpty ? '?' : initiales)),
              title: Text(u?.nomComplet ?? '—',
                  style: Theme.of(context).textTheme.titleMedium),
              subtitle:
                  Text([u?.telephone, u?.email].whereType<String>().join('\n')),
              trailing: IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => modifierProfil(context)),
            ),
          ),
          const SizedBox(height: AppTheme.espaceLg),
          Card(
            child: Column(
              children: [
                tuile(
                    Icons.description_outlined,
                    'Mes quittances',
                    () => ouvrir(
                        context, const QuittancesPage(espaceLocataire: true))),
                tuile(Icons.savings_outlined, 'Ma caution',
                    () => ouvrir(context, const CautionLocatairePage())),
                tuile(
                  Icons.water_drop_outlined,
                  'Mes charges',
                  () => ouvrir(context, const ChargesLocatairePage()),
                  sous: 'Eau, électricité… refacturées',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.espaceLg),
          Card(
            child: Column(
              children: [
                tuile(Icons.notifications_outlined, 'Notifications',
                    () => ouvrir(context, const NotificationsPage())),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Relances par WhatsApp'),
                  subtitle: const Text(
                      'Rappels de loyer et confirmations de paiement'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final choix = await showModalBottomSheet<bool>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ListTile(
                                title: Text(
                                    'Recevoir les messages WhatsApp de votre propriétaire ?')),
                            ListTile(
                                leading: const Icon(Icons.check),
                                title: const Text("J'accepte"),
                                onTap: () => Navigator.pop(ctx, true)),
                            ListTile(
                                leading: const Icon(Icons.close),
                                title: const Text('Je refuse'),
                                onTap: () => Navigator.pop(ctx, false)),
                          ],
                        ),
                      ),
                    );
                    if (choix == null || !context.mounted) return;
                    await reussir(
                      context,
                      () => sl<ConsentirWhatsapp>()(accorde: choix),
                      succes: choix
                          ? 'Consentement enregistré'
                          : 'Consentement retiré',
                    );
                  },
                ),
                tuile(Icons.lock_outline, 'Sécurité',
                    () => ouvrir(context, const SecuritePage())),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.espaceLg),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirmer(
                context,
                titre: 'Se déconnecter',
                message:
                    'Les données enregistrées sur ce téléphone seront effacées.',
                action: 'Se déconnecter',
              );
              if (ok != null && context.mounted) {
                context.read<AuthBloc>().add(DeconnexionDemandee());
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
