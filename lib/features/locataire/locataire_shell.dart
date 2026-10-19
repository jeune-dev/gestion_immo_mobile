import 'package:flutter/material.dart';

import '../../core/widgets/base.dart';
import '../commun/synchronisation.dart';
import 'accueil_screen.dart';
import 'demandes_screen.dart';
import 'loyer_screen.dart';
import 'messages_screen.dart';
import 'profil_locataire_screen.dart';

/// Espace locataire (§ 28) : interface plus simple ; il ne voit jamais les autres locataires.
class LocataireShell extends StatefulWidget {
  const LocataireShell({super.key});

  @override
  State<LocataireShell> createState() => _LocataireShellState();
}

class _LocataireShellState extends State<LocataireShell> {
  int _onglet = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AccueilLocataireScreen(onAller: (i) => setState(() => _onglet = i)),
      const LoyerScreen(),
      const DemandesScreen(),
      const MessagesLocataireScreen(),
      const ProfilLocataireScreen(),
    ];
    return Scaffold(
      body: Column(children: [
        const BandeauHorsLigne(),
        const BandeauSynchronisation(),
        Expanded(child: IndexedStack(index: _onglet, children: pages)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Mon loyer'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Demandes'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
