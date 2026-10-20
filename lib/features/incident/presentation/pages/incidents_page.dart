import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/incident/domain/usecases/get_incidents.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/pages/incident_detail_page.dart';

/// Écran autonome (depuis le tableau de bord).
class IncidentsPage extends StatelessWidget {
  final bool ouverts;
  const IncidentsPage({super.key, this.ouverts = false});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Incidents')),
        body: ListeIncidents(
            cle: GlobalKey<ListePagineeState<Incident>>(), ouverts: ouverts),
      );
}

/// Incidents signalés par les locataires (§ 22) et leur traitement (§ 23).
class ListeIncidents extends StatefulWidget {
  final GlobalKey<ListePagineeState<Incident>> cle;
  final bool ouverts;
  const ListeIncidents({super.key, required this.cle, this.ouverts = false});

  @override
  State<ListeIncidents> createState() => _ListeIncidentsState();
}

class _ListeIncidentsState extends State<ListeIncidents> {
  late String _statut = widget.ouverts ? 'signale' : '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Filtres(
          options: [
            ('', 'Tous'),
            for (final o in refs.options('statut_incident')) (o.code, o.label)
          ],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee<Incident>(
            key: widget.cle,
            cle: _statut,
            vide: 'Aucun incident',
            iconeVide: Icons.report_problem_outlined,
            charger: (page) => sl<GetIncidents>()(
                page: page, statut: _statut.isEmpty ? null : _statut),
            element: (context, i) => ListTile(
              title: Text(i.titre ?? ''),
              subtitle: Text(
                [
                  i.reference,
                  i.immeubleNom,
                  if (i.appartementNumero != null)
                    'Appart. ${i.appartementNumero}',
                  ilYa(i.creeLe),
                ].whereType<String>().join(' · '),
              ),
              trailing:
                  Statut(FamilleStatut.incident, 'statut_incident', i.statut),
              onTap: () async {
                await ouvrir(context, IncidentDetailPage(id: i.id));
                widget.cle.currentState?.recharger();
              },
            ),
          ),
        ),
      ],
    );
  }
}
