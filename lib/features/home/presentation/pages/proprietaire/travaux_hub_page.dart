import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/entities/artisan.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/widgets/formulaire_artisan.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/widgets/liste_artisans.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/widgets/creer_etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/widgets/liste_etats_des_lieux.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/pages/incidents_page.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/widgets/formulaires_incident.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/entities/travaux.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/widgets/formulaires_travaux.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/widgets/liste_travaux.dart';

/// Onglet « Travaux » : chantiers, incidents signalés, artisans, états des lieux.
class TravauxHubPage extends StatefulWidget {
  const TravauxHubPage({super.key});

  @override
  State<TravauxHubPage> createState() => _TravauxHubPageState();
}

class _TravauxHubPageState extends State<TravauxHubPage>
    with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 4, vsync: this)
    ..addListener(() => setState(() {}));
  final _travaux = GlobalKey<ListePagineeState<Travaux>>();
  final _incidents = GlobalKey<ListePagineeState<Incident>>();
  final _artisans = GlobalKey<ListePagineeState<Artisan>>();
  final _edl = GlobalKey<ListePagineeState<EtatDesLieux>>();

  Future<Object?> _formulaire() => switch (_onglets.index) {
        0 => formulaireTravaux(context),
        1 => nouvelIncident(context),
        2 => formulaireArtisan(context),
        _ => creerEtatDesLieux(context),
      };

  Future<void> _ajouter() async {
    final i = _onglets.index;
    if (await _formulaire() == null) return;
    switch (i) {
      case 0:
        _travaux.currentState?.recharger();
      case 1:
        _incidents.currentState?.recharger();
      case 2:
        _artisans.currentState?.recharger();
      default:
        _edl.currentState?.recharger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travaux'),
        bottom: TabBar(
          controller: _onglets,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: fg,
          unselectedLabelColor: fg?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [
            Tab(text: 'Chantiers'),
            Tab(text: 'Incidents'),
            Tab(text: 'Artisans'),
            Tab(text: 'États des lieux'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: Text([
          'Travaux',
          'Incident',
          'Artisan',
          'État des lieux'
        ][_onglets.index]),
      ),
      body: TabBarView(
        controller: _onglets,
        children: [
          ListeTravaux(cle: _travaux),
          ListeIncidents(cle: _incidents),
          ListeArtisans(cle: _artisans),
          ListeEtatsDesLieux(cle: _edl),
        ],
      ),
    );
  }
}
