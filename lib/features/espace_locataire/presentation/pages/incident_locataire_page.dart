import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/incident_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/incident_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/incident_locataire_state.dart';

/// Suivi d'un problème signalé : photos et vidéos, intervention prévue.
class IncidentLocatairePage extends StatelessWidget {
  final String id;
  const IncidentLocatairePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.sl<IncidentLocataireBloc>()..add(LoadIncidentLocataire(id)),
      child: BlocConsumer<IncidentLocataireBloc, IncidentLocataireState>(
        listener: (context, state) {
          if (state is IncidentLocataireSuccess) {
            afficherSucces(context, state.message);
          } else if (state is IncidentLocataireActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is IncidentLocataireInitial ||
            state is IncidentLocataireLoading ||
            state is IncidentLocataireLoaded ||
            state is IncidentLocataireError,
        builder: (context, state) {
          if (state is IncidentLocataireLoaded) {
            return _buildFiche(context, state.incident);
          }
          return VueChargement(
            titre: 'Signalement',
            failure: state is IncidentLocataireError ? state.failure : null,
            onReessayer: () => context
                .read<IncidentLocataireBloc>()
                .add(LoadIncidentLocataire(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, Incident i) {
    final bloc = context.read<IncidentLocataireBloc>();
    Future<void> ajouter({bool video = false}) async {
      final XFile? f = video
          ? await ImagePicker().pickVideo(
              source: ImageSource.camera,
              maxDuration: const Duration(seconds: 60))
          : await choisirPhoto(context);
      if (f != null) bloc.add(AjouterPieceSignalementEvent(id, f.path, video));
    }

    return Scaffold(
      appBar: AppBar(title: Text(i.reference ?? 'Signalement')),
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
                  Statut(FamilleStatut.incident, 'statut_incident', i.statut),
                ],
              ),
              const SizedBox(height: 8),
              Text(i.description ?? ''),
              const SizedBox(height: 8),
              Ligne('Type', refs.libelle('categorie_incident', i.categorie)),
              Ligne('Signalé le', dateHeure(i.creeLe)),
              if (i.analyseLe != null)
                Ligne('Pris en charge le', dateHeure(i.analyseLe)),
              if (i.resoluLe != null) Ligne('Résolu le', dateHeure(i.resoluLe)),
              if (i.motifRejet != null) Ligne('Motif du rejet', i.motifRejet),
            ],
          ),
          const SizedBox(height: AppTheme.espaceLg),
          Section(
            titre: 'Photos et vidéos',
            children: [
              if (i.pieces.isEmpty) const Text('Aucune pièce jointe'),
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
              if (i.ouvert) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                        onPressed: () => ajouter(),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Photo')),
                    OutlinedButton.icon(
                      onPressed: () => ajouter(video: true),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Vidéo'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (i.travaux.isNotEmpty) ...[
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Intervention prévue',
              children: [
                for (final w in i.travaux)
                  Ligne(w.titre ?? 'Travaux', null,
                      widget: Statut(
                          FamilleStatut.travaux, 'statut_travaux', w.statut)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
