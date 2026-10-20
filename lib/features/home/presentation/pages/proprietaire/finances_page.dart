import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/features/caisse/presentation/pages/caisse_page.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/pages/cautions_page.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/pages/depenses_page.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeances_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/charges_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/factures_communes_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/paiements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/rapprochements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/transactions_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/widgets/encaissement.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittances_page.dart';
import 'package:gestion_immo_mobile/features/rapport/presentation/pages/rapports_page.dart';

/// Onglet « Finances » : loyers, paiements, caisse, dépenses, charges, cautions, rapports.
class FinancesPage extends StatelessWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tuile(IconData icone, String titre, String sous,
            Widget Function() ecran) =>
        ListTile(
          leading: CircleAvatar(child: Icon(icone, size: 20)),
          title: Text(titre),
          subtitle: Text(sous),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ouvrir(context, ecran()),
        );
    Widget groupe(String titre, List<Widget> tuiles) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text(titre,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                ...tuiles,
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Finances')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => encaisser(context),
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Encaisser'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          groupe('Loyers', [
            tuile(
                Icons.event_busy_outlined,
                'Impayés',
                'Échéances à payer et en retard',
                () => const EcheancesPage(impayes: true)),
            tuile(Icons.calendar_month_outlined, 'Toutes les échéances',
                'Calendrier des loyers', () => const EcheancesPage()),
            tuile(Icons.receipt_outlined, 'Paiements reçus',
                'Historique, remboursements', () => const PaiementsPage()),
            tuile(
                Icons.fact_check_outlined,
                'Paiements en ligne et preuves',
                'Wave, Orange Money : à valider',
                () => const TransactionsPage()),
            tuile(
                Icons.compare_arrows,
                'À rapprocher',
                'Paiements non identifiés, excédents',
                () => const RapprochementsPage()),
            tuile(
                Icons.description_outlined,
                'Quittances',
                'Consulter, télécharger, partager',
                () => const QuittancesPage()),
          ]),
          groupe('Trésorerie', [
            tuile(Icons.account_balance_wallet_outlined, 'Caisse',
                'Entrées, sorties et solde', () => const CaissePage()),
            tuile(Icons.shopping_bag_outlined, 'Dépenses',
                'Par immeuble et catégorie', () => const DepensesPage()),
          ]),
          groupe('Charges', [
            tuile(
                Icons.water_drop_outlined,
                'Factures communes',
                'Eau, électricité… et répartition',
                () => const FacturesCommunesPage()),
            tuile(Icons.request_quote_outlined, 'Charges refacturées',
                'Part de chaque locataire', () => const ChargesPage()),
          ]),
          groupe('Cautions et rapports', [
            tuile(
                Icons.savings_outlined,
                'Cautions',
                'Versements, retenues, restitutions',
                () => const CautionsPage()),
            tuile(
                Icons.insights_outlined,
                'Rapports',
                'Financier, occupation, travaux, rentabilité',
                () => const RapportsPage()),
          ]),
        ],
      ),
    );
  }
}
