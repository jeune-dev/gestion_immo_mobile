import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/entities/notification_app.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_state.dart';

/// Notifications internes (§ 27) : paiements, retards, incidents, travaux, documents…
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _liste = GlobalKey<ListePagineeState<NotificationApp>>();
  bool _nonLues = false;

  static IconData _icone(String? type) => switch (type) {
        'nouveau_paiement' || 'rapprochement' => Icons.payments_outlined,
        'retard_loyer' || 'echeance' => Icons.schedule,
        'facture' => Icons.receipt_long_outlined,
        'incident' => Icons.report_problem_outlined,
        'nouveau_travail' || 'travail_termine' => Icons.handyman_outlined,
        'depense' => Icons.shopping_bag_outlined,
        'document_disponible' => Icons.description_outlined,
        'nouveau_message' => Icons.chat_bubble_outline,
        'caution' => Icons.savings_outlined,
        'etat_des_lieux' => Icons.fact_check_outlined,
        'abonnement' => Icons.workspace_premium_outlined,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>(),
      child: BlocListener<NotificationsBloc, NotificationsState>(
        // Après chaque action (réussie ou non), la liste se recharge.
        listener: (context, state) {
          if (state is NotificationsError) {
            afficherErreurApi(context, state.failure);
          } else if (state is NotificationsSuccess) {
            afficherSucces(context, state.message);
          }
          _liste.currentState?.recharger();
        },
        child: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Notifications'),
              actions: [
                IconButton(
                  tooltip: 'Tout marquer comme lu',
                  icon: const Icon(Icons.done_all),
                  onPressed: () =>
                      context.read<NotificationsBloc>().add(ToutLireEvent()),
                ),
              ],
            ),
            body: Column(
              children: [
                Filtres(
                  options: const [
                    ('toutes', 'Toutes'),
                    ('non_lues', 'Non lues')
                  ],
                  valeur: _nonLues ? 'non_lues' : 'toutes',
                  onChange: (v) => setState(() => _nonLues = v == 'non_lues'),
                ),
                Expanded(
                  child: ListePaginee<NotificationApp>(
                    key: _liste,
                    cle: _nonLues,
                    vide: 'Aucune notification',
                    iconeVide: Icons.notifications_none,
                    charger: (page) =>
                        sl<GetNotifications>()(page: page, nonLues: _nonLues),
                    element: (context, n) => ListTile(
                      tileColor: n.lue ? null : context.palette.primaireTeinte,
                      leading: Icon(_icone(n.type),
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(n.titre,
                          style: TextStyle(
                              fontWeight:
                                  n.lue ? FontWeight.w400 : FontWeight.w600)),
                      subtitle: Text('${n.corps}\n${ilYa(n.creeLe)}'),
                      isThreeLine: true,
                      onTap: n.lue
                          ? null
                          : () => context
                              .read<NotificationsBloc>()
                              .add(MarquerNotificationLueEvent(n.id)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
