import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/navigation.dart';
import '../../../core/widgets/sources.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';
import 'travaux_screen.dart';

/// Écran autonome (depuis le tableau de bord).
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key, this.ouverts = false});
  final bool ouverts;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Incidents')),
        body: ListeIncidents(cle: GlobalKey<ListePagineeState>(), ouverts: ouverts),
      );
}

/// Incidents signalés par les locataires (§ 22) et leur traitement (§ 23).
class ListeIncidents extends StatefulWidget {
  const ListeIncidents({super.key, required this.cle, this.ouverts = false});
  final GlobalKey<ListePagineeState> cle;
  final bool ouverts;

  @override
  State<ListeIncidents> createState() => _ListeIncidentsState();
}

class _ListeIncidentsState extends State<ListeIncidents> {
  late String _statut = widget.ouverts ? 'signale' : '';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Filtres(
        options: [('', 'Tous'), for (final o in refs.options('statut_incident')) (o.code, o.label)],
        valeur: _statut,
        onChange: (v) => setState(() => _statut = v),
      ),
      Expanded(
        child: ListePaginee(
          key: widget.cle,
          cle: _statut,
          vide: 'Aucun incident',
          iconeVide: Icons.report_problem_outlined,
          charger: (page) => api.get('/incidents', query: {'page': page, 'status': _statut, 'tri': '-created_at'}),
          element: (context, i) => ListTile(
            title: Text('${i['title']}'),
            subtitle: Text([
              '${i['reference']}',
              (i['building'] as Map?)?['name'],
              if (i['apartment'] != null) 'Appart. ${(i['apartment'] as Map)['number']}',
              ilYa(i['created_at'] as String?),
            ].whereType<String>().join(' · ')),
            trailing: Statut(FamilleStatut.incident, 'statut_incident', i['status'] as String?),
            onTap: () async {
              await ouvrir(context, IncidentDetail(id: '${i['id']}'));
              widget.cle.currentState?.recharger();
            },
          ),
        ),
      ),
    ]);
  }
}

class IncidentDetail extends StatelessWidget {
  const IncidentDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<List<dynamic>>(
      page: true,
      titre: 'Incident',
      charger: () => Future.wait([
        api.get<Map<String, dynamic>>('/incidents/$id'),
        api.get<Map<String, dynamic>>('/documents', query: {'entity_type': 'incident', 'entity_id': id}),
      ]),
      builder: (context, data, recharger) {
        final i = (data[0] as Map)['incident'] as Map;
        final pieces = ((data[1] as Map)['items'] as List).cast<Map>();
        final statut = i['status'] as String;
        final travaux = ((i['work_orders'] as List?) ?? []).cast<Map>();

        Future<void> note(String route, String titre, String succes, {bool motif = false}) async {
          final texte = await confirmer(context,
              titre: titre,
              message: motif ? 'Le locataire sera informé du motif.' : 'Ajoutez une note pour le locataire (facultatif).',
              motif: true,
              motifObligatoire: motif,
              libelleMotif: motif ? 'Motif' : 'Note',
              danger: motif);
          if (texte == null || !context.mounted) return;
          await executer(context, () => api.post<dynamic>('/incidents/$id/$route', body: motif ? {'reason': texte} : {if (texte.isNotEmpty) 'note': texte}),
              succes: succes);
          recharger();
        }

        return Scaffold(
          appBar: AppBar(title: Text('${i['reference']}')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Row(children: [
                Expanded(child: Text('${i['title']}', style: Theme.of(context).textTheme.titleMedium)),
                Statut(FamilleStatut.incident, 'statut_incident', statut),
              ]),
              const SizedBox(height: AppTheme.espaceSm),
              Text('${i['description']}'),
              const SizedBox(height: AppTheme.espaceSm),
              Ligne('Catégorie', refs.libelle('categorie_incident', i['category'] as String?)),
              Ligne('Logement', '${(i['building'] as Map?)?['name'] ?? ''}${i['apartment'] != null ? ' · ${(i['apartment'] as Map)['number']}' : ''}'),
              Ligne('Signalé par', i['tenant'] == null ? 'Vous' : nomComplet(i['tenant'] as Map)),
              Ligne('Signalé le', dateHeure(i['created_at'] as String?)),
              if (i['owner_note'] != null) Ligne('Note', '${i['owner_note']}'),
              if (i['rejection_reason'] != null) Ligne('Motif du rejet', '${i['rejection_reason']}'),
            ]),
            if (pieces.isNotEmpty) ...[
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Photos et vidéos du locataire', children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final d in pieces)
                    InkWell(
                      onTap: () => ouvrirDocument(context, d),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.rayon),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: '${d['mime_type']}'.startsWith('image/') ? ImageApi('${d['id']}') : const Icon(Icons.videocam_outlined),
                        ),
                      ),
                    ),
                ]),
              ]),
            ],
            if (travaux.isNotEmpty) ...[
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Travaux liés', padding: false, children: [
                for (final w in travaux)
                  ListTile(
                    title: Text('${w['reference'] ?? ''} ${w['title'] ?? ''}'),
                    trailing: Statut(FamilleStatut.travaux, 'statut_travaux', w['status'] as String?),
                    onTap: () => ouvrirTravaux(context, '${w['id']}'),
                  ),
              ]),
            ],
            const SizedBox(height: AppTheme.espaceLg),
            if (statut == 'signale')
              OutlinedButton.icon(
                onPressed: () => note('analyser', 'Prendre en charge', 'Incident en analyse'),
                icon: const Icon(Icons.search),
                label: const Text('Prendre en charge (en analyse)'),
              ),
            if (['signale', 'en_analyse'].contains(statut)) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final cle = nouvelleCle();
                  final r = await EcranFormulaire.ouvrir<Map>(
                    context,
                    EcranFormulaire(
                      titre: 'Planifier des travaux',
                      initial: {'title': i['title'], 'priority': 'normale', 'status': 'valide'},
                      champs: [
                        const Champ('title', 'Intitulé', maxLongueur: 150),
                        const Champ('category', 'Catégorie', type: TypeChamp.selection, referentiel: 'categorie_travaux', obligatoire: true),
                        const Champ('priority', 'Priorité', type: TypeChamp.selection, referentiel: 'priorite'),
                        Champ('contractor_id', 'Artisan', type: TypeChamp.entite, entite: Sources.artisans),
                        const Champ('estimated_amount', 'Coût estimé', type: TypeChamp.montant),
                        const Champ('scheduled_for', 'Date prévue', type: TypeChamp.date),
                        const Champ('note', 'Note pour le locataire', type: TypeChamp.multiligne, maxLongueur: 2000),
                      ],
                      libelleEnvoi: 'Planifier',
                      messageSucces: 'Travaux planifiés',
                      envoyer: (c) => api.post<Map<String, dynamic>>('/incidents/$id/travaux', body: c, idempotence: cle),
                    ),
                  );
                  if (r != null) recharger();
                },
                icon: const Icon(Icons.handyman_outlined),
                label: const Text('Planifier des travaux'),
              ),
            ],
            if (['signale', 'en_analyse', 'travaux_planifies'].contains(statut)) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => note('resoudre', "Marquer l'incident comme résolu", 'Incident résolu'),
                icon: const Icon(Icons.check),
                label: const Text('Marquer comme résolu'),
              ),
            ],
            if (['signale', 'en_analyse'].contains(statut))
              TextButton(
                onPressed: () => note('rejeter', "Rejeter l'incident", 'Incident rejeté', motif: true),
                child: Text('Rejeter', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ]),
        );
      },
    );
  }
}
