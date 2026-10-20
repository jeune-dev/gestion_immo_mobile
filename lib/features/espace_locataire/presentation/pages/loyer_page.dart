import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittances_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_echeances.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_paiements.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_transactions.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/paiement_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';

/// « Mon loyer » et « Mes paiements » (§ 28).
class LoyerPage extends StatefulWidget {
  const LoyerPage({super.key});

  @override
  State<LoyerPage> createState() => _LoyerPageState();
}

class _LoyerPageState extends State<LoyerPage>
    with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 3, vsync: this);
  final _echeances = GlobalKey<ListePagineeState<Echeance>>();
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
            onPressed: () =>
                ouvrir(context, const QuittancesPage(espaceLocataire: true)),
          ),
        ],
        bottom: TabBar(
          controller: _onglets,
          labelColor: fg,
          unselectedLabelColor: fg?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [
            Tab(text: 'Échéances'),
            Tab(text: 'Paiements'),
            Tab(text: 'En ligne'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _onglets,
        children: [
          Column(
            children: [
              Filtres(
                options: const [('a_payer', 'À payer'), ('toutes', 'Toutes')],
                valeur: _aPayer ? 'a_payer' : 'toutes',
                onChange: (v) => setState(() => _aPayer = v == 'a_payer'),
              ),
              Expanded(
                child: ListePaginee<Echeance>(
                  key: _echeances,
                  cle: _aPayer,
                  vide: _aPayer
                      ? 'Vous êtes à jour : rien à payer.'
                      : 'Aucune échéance',
                  iconeVide:
                      _aPayer ? Icons.verified_outlined : Icons.event_outlined,
                  charger: (page) =>
                      sl<GetMesEcheances>()(page: page, aPayer: _aPayer),
                  element: (context, e) => ListTile(
                    title: Text(e.libelle ?? ''),
                    subtitle: Text(
                        'À payer avant le ${date(e.dateEcheance)}${e.montantPaye > 0 ? ' · déjà payé ${montant(e.montantPaye)}' : ''}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Montant(
                          e.payable ? e.reste : e.montantDu,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: e.statut == 'en_retard'
                                  ? context.palette.danger
                                  : null),
                        ),
                        Statut(FamilleStatut.echeance, 'statut_echeance',
                            e.statut),
                      ],
                    ),
                    onTap: e.payable && e.bailId != null
                        ? () async {
                            if (await payer(context,
                                    echeance: e, bailId: e.bailId!) ==
                                true) {
                              _echeances.currentState?.recharger();
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
          ListePaginee<Paiement>(
            vide: 'Aucun paiement enregistré',
            charger: (page) => sl<GetMesPaiements>()(page: page),
            element: (context, p) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(montant(p.montant), style: chiffresFixes),
              subtitle: Text(
                  '${date(p.payeLe)} · ${refs.libelle('mode_paiement', p.moyen)} · ${p.reference ?? ''}'),
              trailing:
                  Statut(FamilleStatut.paiement, 'statut_paiement', p.statut),
            ),
          ),
          ListePaginee<TransactionPaiement>(
            vide: 'Aucun paiement en ligne',
            charger: (page) => sl<GetMesTransactions>()(page: page),
            element: (context, t) => ListTile(
              title: Text(
                  '${montant(t.montant)} · ${refs.libelle('portefeuille', t.portefeuille)}'),
              subtitle: Text(
                '${refs.libelle('mode_transaction', t.mode)} · ${dateHeure(t.creeLe)}${t.motifRejet != null ? '\nRefusé : ${t.motifRejet}' : ''}',
              ),
              trailing: Statut(
                  FamilleStatut.transaction, 'statut_transaction', t.statut),
              onTap: () => ouvrir(context,
                  SuiviTransactionPage(id: t.id, checkoutUrl: t.checkoutUrl)),
            ),
          ),
        ],
      ),
    );
  }
}
