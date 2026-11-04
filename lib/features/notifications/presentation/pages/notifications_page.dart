import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/config/user_role.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/entities/notification_app.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/compteur_notifications.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/widgets/ouvrir_notification.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Notifications internes (§ 27) : paiements, retards, incidents, travaux, documents…
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _liste = GlobalKey<ListePagineeState<NotificationApp>>();
  bool _nonLues = false;
  bool _ouverture = false;

  late final bool _locataire;

  @override
  void initState() {
    super.initState();
    _locataire =
        context.read<AuthBloc>().state.compte?.utilisateur.role ==
        UserRole.locataire;
  }

  /// Marque la notification comme lue et ouvre ce qu'elle concerne.
  Future<void> _ouvrir(BuildContext context, NotificationApp n) async {
    if (!n.lue) {
      context.read<NotificationsBloc>().add(MarquerNotificationLueEvent(n.id));
    }
    if (_ouverture || !notificationOuvrable(n, locataire: _locataire)) return;
    _ouverture = true;
    // Contexte de la page : la tuile peut disparaître quand la liste se recharge.
    await ouvrirNotification(this.context, n, locataire: _locataire);
    _ouverture = false;
    _liste.currentState?.recharger();
  }

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
          CompteurNotifications.rafraichir();
        },
        child: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              flexibleSpace: const FondMarque(),
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
                    ('non_lues', 'Non lues'),
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
                    element: (context, n) {
                      final ouvrable = notificationOuvrable(
                        n,
                        locataire: _locataire,
                      );
                      final p = context.palette;
                      return InkWell(
                        onTap: n.lue && !ouvrable
                            ? null
                            : () => _ouvrir(context, n),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.espaceMd),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconeOption(_icone(n.type)),
                              const SizedBox(width: AppTheme.espaceMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.titre,
                                      style: TextStyle(
                                        color: p.texte,
                                        fontSize: 15,
                                        fontWeight: n.lue
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      n.corps,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: p.texteSecondaire,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.espaceXs),
                                    Text(
                                      ilYa(n.creeLe),
                                      style: TextStyle(
                                        color: p.texteDiscret,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!n.lue)
                                Container(
                                  width: 9,
                                  height: 9,
                                  margin: const EdgeInsets.only(
                                    left: AppTheme.espaceSm,
                                    top: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else if (ouvrable)
                                Icon(
                                  Icons.chevron_right,
                                  color: p.texteDiscret,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
