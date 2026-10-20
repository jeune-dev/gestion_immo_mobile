import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/widgets/bandeau_synchronisation.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/accueil_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/demandes_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/loyer_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/profil_locataire_page.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/messagerie_page.dart';

/// Espace locataire (§ 28) : interface plus simple ; il ne voit jamais les autres locataires.
class LocataireHomePage extends StatefulWidget {
  const LocataireHomePage({super.key});

  @override
  State<LocataireHomePage> createState() => _LocataireHomePageState();
}

class _LocataireHomePageState extends State<LocataireHomePage> {
  int _onglet = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AccueilLocatairePage(onAller: (i) => setState(() => _onglet = i)),
      const LoyerPage(),
      const DemandesPage(),
      const MessageriePage(espaceLocataire: true),
      const ProfilLocatairePage(),
    ];
    return Scaffold(
      body: Column(
        children: [
          const BandeauHorsLigne(),
          const BandeauSynchronisation(),
          Expanded(
            child: IndexedStack(index: _onglet, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Mon loyer'),
          NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build),
              label: 'Demandes'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Messages'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}
