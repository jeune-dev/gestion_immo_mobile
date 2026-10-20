import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/services/file_attente_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/bandeau_synchronisation.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/pages/categories_page.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/messagerie_page.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/moyens_paiement_page.dart';
import 'package:gestion_immo_mobile/features/parametres/presentation/pages/parametres_page.dart';
import 'package:gestion_immo_mobile/features/parametres/presentation/widgets/formulaire_espace.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/modifier_profil.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/securite_page.dart';

/// Onglet « Profil » du propriétaire.
class ProfilProprietairePage extends StatelessWidget {
  const ProfilProprietairePage({super.key});

  @override
  Widget build(BuildContext context) {
    final compte = context.select((AuthBloc b) => b.state.compte);
    final u = compte?.utilisateur;
    final abo = compte?.abonnement;
    final file = sl<FileAttenteService>();
    Widget tuile(IconData i, String t, VoidCallback onTap,
            {String? sous, Widget? fin}) =>
        ListTile(
          leading: Icon(i),
          title: Text(t),
          subtitle: sous == null ? null : Text(sous),
          trailing: fin ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        );
    final initiales =
        '${(u?.prenom ?? '').isNotEmpty ? u!.prenom[0] : ''}${(u?.nom ?? '').isNotEmpty ? u!.nom[0] : ''}'
            .toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                  radius: 28,
                  child: Text(initiales.isEmpty ? '?' : initiales,
                      style: const TextStyle(fontSize: 18))),
              title: Text(u?.nomComplet ?? '—',
                  style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text([compte?.espace?.societe, u?.telephone, u?.email]
                  .whereType<String>()
                  .join('\n')),
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
                  Icons.workspace_premium_outlined,
                  'Abonnement',
                  () => context.push(AppRouter.abonnement),
                  sous:
                      '${abo?.plan ?? ''} · jusqu’au ${date(abo?.finPeriode)}',
                  fin: Statut(FamilleStatut.abonnement, 'statut_abonnement',
                      abo?.statut),
                ),
                tuile(
                  Icons.store_outlined,
                  'Mon espace propriétaire',
                  () => modifierEspaceBailleur(context),
                  sous: 'Nom affiché, coordonnées sur les quittances',
                ),
                tuile(Icons.tune, 'Relances et règles de gestion',
                    () => ouvrir(context, const ParametresPage())),
                tuile(
                  Icons.account_balance_outlined,
                  'Moyens de paiement',
                  () => ouvrir(context, const MoyensPaiementPage()),
                  sous: 'Wave, Orange Money, PayDunya',
                ),
                tuile(Icons.category_outlined, 'Catégories de dépenses',
                    () => ouvrir(context, const CategoriesPage())),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.espaceLg),
          Card(
            child: Column(
              children: [
                tuile(Icons.chat_bubble_outline, 'Messagerie',
                    () => ouvrir(context, const MessageriePage())),
                tuile(Icons.notifications_outlined, 'Notifications',
                    () => ouvrir(context, const NotificationsPage())),
                tuile(Icons.lock_outline, 'Sécurité',
                    () => ouvrir(context, const SecuritePage())),
                ListenableBuilder(
                  listenable: file,
                  builder: (context, _) => file.operations.isEmpty
                      ? const SizedBox.shrink()
                      : tuile(
                          Icons.cloud_upload_outlined,
                          'Opérations en attente',
                          () => ouvrir(context, const OperationsPage()),
                          fin: Badge(label: Text('${file.operations.length}')),
                        ),
                ),
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
