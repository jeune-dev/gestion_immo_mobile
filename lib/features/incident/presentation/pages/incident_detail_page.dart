import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/pages/travaux_detail_page.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/bloc/incident_bloc.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/bloc/incident_event.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/bloc/incident_state.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/widgets/formulaires_incident.dart';

class IncidentDetailPage extends StatelessWidget {
  final String id;
  const IncidentDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<IncidentBloc>()..add(LoadIncident(id)),
      child: BlocConsumer<IncidentBloc, IncidentState>(
        listener: (context, state) {
          if (state is IncidentSuccess) {
            afficherSucces(context, state.message);
          } else if (state is IncidentActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is IncidentInitial ||
            state is IncidentLoading ||
            state is IncidentLoaded ||
            state is IncidentError,
        builder: (context, state) {
          if (state is IncidentLoaded) {
            return _buildFiche(context, state.incident);
          }
          return VueChargement(
            titre: 'Incident',
            failure: state is IncidentError ? state.failure : null,
            onReessayer: () =>
                context.read<IncidentBloc>().add(LoadIncident(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, Incident i) {
    final bloc = context.read<IncidentBloc>();
    Future<String?> note(String titre, {bool motif = false}) => confirmer(
          context,
          titre: titre,
          message: motif
              ? 'Le locataire sera informé du motif.'
              : 'Ajoutez une note pour le locataire (facultatif).',
          motif: true,
          motifObligatoire: motif,
          libelleMotif: motif ? 'Motif' : 'Note',
          danger: motif,
        );
    final statut = i.statut;
    return Scaffold(
      appBar: AppBar(title: Text(i.reference ?? 'Incident')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Section(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(i.titre ?? '',
                          style: Theme.of(context).textTheme.titleMedium)),
                  Statut(FamilleStatut.incident, 'statut_incident', statut),
                ],
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Text(i.description ?? ''),
              const SizedBox(height: AppTheme.espaceSm),
              Ligne(
                  'Catégorie', refs.libelle('categorie_incident', i.categorie)),
              Ligne('Logement',
                  '${i.immeubleNom ?? ''}${i.appartementNumero != null ? ' · ${i.appartementNumero}' : ''}'),
              Ligne('Signalé par',
                  i.locataire == null ? 'Vous' : i.locataire!.nomComplet),
              Ligne('Signalé le', dateHeure(i.creeLe)),
              if (i.note != null) Ligne('Note', i.note),
              if (i.motifRejet != null) Ligne('Motif du rejet', i.motifRejet),
            ],
          ),
          if (i.pieces.isNotEmpty) ...[
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Photos et vidéos du locataire',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in i.pieces)
                      InkWell(
                        onTap: () => ouvrirDocument(context, d),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.rayon),
                          child: SizedBox(
                              width: 88,
                              height: 88,
                              child: d.estImage
                                  ? ImageApi(d.id)
                                  : const Icon(Icons.videocam_outlined)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
          if (i.travaux.isNotEmpty) ...[
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Travaux liés',
              padding: false,
              children: [
                for (final w in i.travaux)
                  ListTile(
                    title: Text('${w.reference ?? ''} ${w.titre ?? ''}'),
                    trailing: Statut(
                        FamilleStatut.travaux, 'statut_travaux', w.statut),
                    onTap: () => ouvrirTravaux(context, w.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.espaceLg),
          if (statut == 'signale')
            OutlinedButton.icon(
              onPressed: () async {
                final texte = await note('Prendre en charge');
                if (texte != null) {
                  bloc.add(
                      AnalyserIncidentEvent(id, texte.isEmpty ? null : texte));
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('Prendre en charge (en analyse)'),
            ),
          if (['signale', 'en_analyse'].contains(statut)) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                if (await planifierTravaux(context, i)) {
                  bloc.add(RafraichirIncident(id));
                }
              },
              icon: const Icon(Icons.handyman_outlined),
              label: const Text('Planifier des travaux'),
            ),
          ],
          if (['signale', 'en_analyse', 'travaux_planifies']
              .contains(statut)) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final texte = await note("Marquer l'incident comme résolu");
                if (texte != null) {
                  bloc.add(
                      ResoudreIncidentEvent(id, texte.isEmpty ? null : texte));
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Marquer comme résolu'),
            ),
          ],
          if (['signale', 'en_analyse'].contains(statut))
            TextButton(
              onPressed: () async {
                final motif = await note("Rejeter l'incident", motif: true);
                if (motif != null) bloc.add(RejeterIncidentEvent(id, motif));
              },
              child: Text('Rejeter',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }
}
