import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/features/account/presentation/pages/profil_proprietaire_page.dart';
import 'package:gestion_immo_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:gestion_immo_mobile/features/home/presentation/pages/proprietaire/biens_page.dart';
import 'package:gestion_immo_mobile/features/home/presentation/pages/proprietaire/finances_page.dart';
import 'package:gestion_immo_mobile/features/home/presentation/pages/proprietaire/travaux_hub_page.dart';

/// Espace propriétaire : navigation recommandée par le cahier des charges (§ 36)
/// Accueil · Biens · Finances · Travaux · Profil.
class ProprietaireHomePage extends StatefulWidget {
  const ProprietaireHomePage({super.key});

  @override
  State<ProprietaireHomePage> createState() => _ProprietaireHomePageState();
}

class _ProprietaireHomePageState extends State<ProprietaireHomePage> {
  int _onglet = 0;

  final _actualisation = ValueNotifier<int>(0);

  void _aller(int i) {
    if (i == 0 && _onglet != 0) _actualisation.value++;
    setState(() => _onglet = i);
  }

  @override
  void dispose() {
    _actualisation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onAller: _aller, actualisation: _actualisation),
      const BiensPage(),
      const FinancesPage(),
      const TravauxHubPage(),
      const ProfilProprietairePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _onglet, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: _aller,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Biens',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finances',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Travaux',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
