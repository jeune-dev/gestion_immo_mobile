import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/session_cubit.dart';
import '../../core/widgets/base.dart';
import '../commun/synchronisation.dart';
import 'biens/biens_screen.dart';
import 'dashboard_screen.dart';
import 'finances/finances_screen.dart';
import 'profil_screen.dart';
import 'travaux/travaux_hub_screen.dart';

/// Espace propriétaire : navigation recommandée par le cahier des charges (§ 36)
/// Accueil · Biens · Finances · Travaux · Profil.
class ProprietaireShell extends StatefulWidget {
  const ProprietaireShell({super.key});

  @override
  State<ProprietaireShell> createState() => _ProprietaireShellState();
}

class _ProprietaireShellState extends State<ProprietaireShell> {
  int _onglet = 0;

  void _aller(int i) => setState(() => _onglet = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onAller: _aller),
      const BiensScreen(),
      const FinancesScreen(),
      const TravauxHubScreen(),
      const ProfilProprietaireScreen(),
    ];
    return BlocBuilder<SessionCubit, Session>(
      builder: (context, session) => Scaffold(
        body: Column(children: [
          const BandeauHorsLigne(),
          const BandeauSynchronisation(),
          Expanded(child: IndexedStack(index: _onglet, children: pages)),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _onglet,
          onDestinationSelected: _aller,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'Biens'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finances'),
            NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'Travaux'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
