import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/chargement.dart';
import '../../theme/app_colors.dart';

/// Compteur des notifications non lues (rafraîchi à chaque affichage).
class BoutonNotifications extends StatefulWidget {
  const BoutonNotifications({super.key});

  @override
  State<BoutonNotifications> createState() => _BoutonNotificationsState();
}

class _BoutonNotificationsState extends State<BoutonNotifications> {
  int _n = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final r = await api.get<Map<String, dynamic>>('/notifications/compteur', cache: false);
      if (mounted) setState(() => _n = entier(r['non_lues']));
    } catch (_) {
      // Sans réseau : pas de pastille
    }
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: _n > 0,
      label: Text(_n > 99 ? '99+' : '$_n'),
      child: const Icon(Icons.notifications_outlined),
    );
  }
}

/// Notifications internes (§ 27) : paiements, retards, incidents, travaux, documents…
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _liste = GlobalKey<ListePagineeState>();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Tout marquer comme lu',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await executer(context, () => api.post<dynamic>('/notifications/tout-lire'), succes: 'Notifications lues');
              _liste.currentState?.recharger();
            },
          ),
        ],
      ),
      body: Column(children: [
        Filtres(
          options: const [('toutes', 'Toutes'), ('non_lues', 'Non lues')],
          valeur: _nonLues ? 'non_lues' : 'toutes',
          onChange: (v) => setState(() => _nonLues = v == 'non_lues'),
        ),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _nonLues,
            vide: 'Aucune notification',
            iconeVide: Icons.notifications_none,
            charger: (page) => api.get<Map<String, dynamic>>('/notifications', query: {'page': page, if (_nonLues) 'non_lues': true}),
            element: (context, n) {
              final lue = n['read_at'] != null;
              return ListTile(
                tileColor: lue ? null : context.palette.primaireTeinte,
                leading: Icon(_icone(n['type'] as String?), color: Theme.of(context).colorScheme.primary),
                title: Text('${n['title']}', style: TextStyle(fontWeight: lue ? FontWeight.w400 : FontWeight.w600)),
                subtitle: Text('${n['body']}\n${ilYa(n['created_at'] as String?)}'),
                isThreeLine: true,
                onTap: lue
                    ? null
                    : () async {
                        await executer(context, () => api.post<dynamic>('/notifications/${n['id']}/lue'));
                        _liste.currentState?.recharger();
                      },
              );
            },
          ),
        ),
      ]),
    );
  }
}
