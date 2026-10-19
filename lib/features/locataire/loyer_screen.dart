import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/statuts.dart';
import '../proprietaire/finances/quittances_screen.dart';
import 'paiement.dart';

/// « Mon loyer » et « Mes paiements » (§ 28).
class LoyerScreen extends StatefulWidget {
  const LoyerScreen({super.key});

  @override
  State<LoyerScreen> createState() => _LoyerScreenState();
}

class _LoyerScreenState extends State<LoyerScreen> with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 3, vsync: this);
  final _echeances = GlobalKey<ListePagineeState>();
  bool _aPayer = true;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon loyer'),
        actions: [
          IconButton(
            tooltip: 'Mes quittances',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => ouvrir(context, const QuittancesScreen(chemin: '/locataire/quittances')),
          ),
        ],
        bottom: TabBar(
          controller: _onglets,
          labelColor: fg,
          unselectedLabelColor: fg?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [Tab(text: 'Échéances'), Tab(text: 'Paiements'), Tab(text: 'En ligne')],
        ),
      ),
      body: TabBarView(controller: _onglets, children: [
        Column(children: [
          Filtres(
            options: const [('a_payer', 'À payer'), ('toutes', 'Toutes')],
            valeur: _aPayer ? 'a_payer' : 'toutes',
            onChange: (v) => setState(() => _aPayer = v == 'a_payer'),
          ),
          Expanded(
            child: ListePaginee(
              key: _echeances,
              cle: _aPayer,
              vide: _aPayer ? 'Vous êtes à jour : rien à payer.' : 'Aucune échéance',
              iconeVide: _aPayer ? Icons.verified_outlined : Icons.event_outlined,
              charger: (page) => api.get('/locataire/echeances', query: {'page': page, if (_aPayer) 'a_payer': true, 'ordre': _aPayer ? 'asc' : 'desc'}),
              element: (context, e) {
                final reste = entier(e['amount_due']) - entier(e['amount_paid']);
                final payable = ['a_payer', 'partiellement_paye', 'en_retard'].contains(e['status']);
                return ListTile(
                  title: Text('${e['label']}'),
                  subtitle: Text('À payer avant le ${date(e['due_date'] as String?)}${entier(e['amount_paid']) > 0 ? ' · déjà payé ${montant(e['amount_paid'] as num?)}' : ''}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Montant(payable ? reste : entier(e['amount_due']),
                        style: TextStyle(fontWeight: FontWeight.w600, color: e['status'] == 'en_retard' ? context.palette.danger : null)),
                    Statut(FamilleStatut.echeance, 'statut_echeance', e['status'] as String?),
                  ]),
                  onTap: payable
                      ? () async {
                          if (await payer(context, echeance: e, bailId: '${e['lease_id']}') == true) _echeances.currentState?.recharger();
                        }
                      : null,
                );
              },
            ),
          ),
        ]),
        ListePaginee(
          vide: 'Aucun paiement enregistré',
          charger: (page) => api.get('/locataire/paiements', query: {'page': page}),
          element: (context, p) => ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(montant(p['amount'] as num?), style: chiffresFixes),
            subtitle: Text('${date(p['paid_on'] as String?)} · ${refs.libelle('mode_paiement', p['method'] as String?)} · ${p['reference']}'),
            trailing: Statut(FamilleStatut.paiement, 'statut_paiement', p['status'] as String?),
          ),
        ),
        ListePaginee(
          vide: 'Aucun paiement en ligne',
          charger: (page) => api.get('/locataire/paiements/transactions', query: {'page': page}),
          element: (context, t) => ListTile(
            title: Text('${montant(t['amount'] as num?)} · ${refs.libelle('portefeuille', t['wallet'] as String?)}'),
            subtitle: Text('${refs.libelle('mode_transaction', t['mode'] as String?)} · ${dateHeure(t['created_at'] as String?)}'
                '${t['rejection_reason'] != null ? '\nRefusé : ${t['rejection_reason']}' : ''}'),
            trailing: Statut(FamilleStatut.transaction, 'statut_transaction', t['status'] as String?),
            onTap: () => ouvrir(context, SuiviTransactionScreen(id: '${t['id']}', checkoutUrl: t['checkout_url'] as String?)),
          ),
        ),
      ]),
    );
  }
}
