import 'package:flutter/material.dart';

import '../../../core/widgets/navigation.dart';
import '../../../theme/app_theme.dart';
import 'caisse_screen.dart';
import 'cautions_screen.dart';
import 'depenses_screen.dart';
import 'echeances_screen.dart';
import 'encaissement.dart';
import 'factures_screen.dart';
import 'paiements_screen.dart';
import 'quittances_screen.dart';
import 'rapports_screen.dart';
import 'transactions_screen.dart';

/// Onglet « Finances » : loyers, paiements, caisse, dépenses, charges, cautions, rapports.
class FinancesScreen extends StatelessWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tuile(IconData icone, String titre, String sous, Widget Function() ecran) => ListTile(
          leading: CircleAvatar(child: Icon(icone, size: 20)),
          title: Text(titre),
          subtitle: Text(sous),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ouvrir(context, ecran()),
        );
    Widget groupe(String titre, List<Widget> tuiles) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
          child: Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text(titre, style: Theme.of(context).textTheme.titleMedium)),
              ...tuiles,
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Finances')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => encaisser(context),
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Encaisser'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
        groupe('Loyers', [
          tuile(Icons.event_busy_outlined, 'Impayés', 'Échéances à payer et en retard', () => const EcheancesScreen(impayes: true)),
          tuile(Icons.calendar_month_outlined, 'Toutes les échéances', 'Calendrier des loyers', () => const EcheancesScreen()),
          tuile(Icons.receipt_outlined, 'Paiements reçus', 'Historique, remboursements', () => const PaiementsScreen()),
          tuile(Icons.fact_check_outlined, 'Paiements en ligne et preuves', 'Wave, Orange Money : à valider', () => const TransactionsScreen()),
          tuile(Icons.compare_arrows, 'À rapprocher', 'Paiements non identifiés, excédents', () => const RapprochementsScreen()),
          tuile(Icons.description_outlined, 'Quittances', 'Consulter, télécharger, partager', () => const QuittancesScreen()),
        ]),
        groupe('Trésorerie', [
          tuile(Icons.account_balance_wallet_outlined, 'Caisse', 'Entrées, sorties et solde', () => const CaisseScreen()),
          tuile(Icons.shopping_bag_outlined, 'Dépenses', 'Par immeuble et catégorie', () => const DepensesScreen()),
        ]),
        groupe('Charges', [
          tuile(Icons.water_drop_outlined, 'Factures communes', 'Eau, électricité… et répartition', () => const FacturesScreen()),
          tuile(Icons.request_quote_outlined, 'Charges refacturées', 'Part de chaque locataire', () => const ChargesScreen()),
        ]),
        groupe('Cautions et rapports', [
          tuile(Icons.savings_outlined, 'Cautions', 'Versements, retenues, restitutions', () => const CautionsScreen()),
          tuile(Icons.insights_outlined, 'Rapports', 'Financier, occupation, travaux, rentabilité', () => const RapportsScreen()),
        ]),
      ]),
    );
  }
}
