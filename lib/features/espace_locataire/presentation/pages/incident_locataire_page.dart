import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/video_api.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/incident_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/incident_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/incident_locataire_state.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

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
            onReessayer: () => context.read<IncidentLocataireBloc>().add(
              LoadIncidentLocataire(id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, Incident i) {
    final bloc = context.read<IncidentLocataireBloc>();
    Future<void> ajouter({bool video = false}) async {
      final XFile? f = video
          ? await choisirVideo(context)
          : await choisirPhoto(context);
      if (f != null) bloc.add(AjouterPieceSignalementEvent(id, f.path, video));
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Mon signalement'),
      ),
      body: VueIncident(
        i: i,
        onPhoto: () => ajouter(),
        onVideo: () => ajouter(video: true),
      ),
    );
  }
}

/// Fiche d'un signalement : résumé, avancement, description et pièces jointes.
class VueIncident extends StatelessWidget {
  final Incident i;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  const VueIncident({
    super.key,
    required this.i,
    required this.onPhoto,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.espaceLg),
      children: [
        CarteMarque(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      refs
                          .libelle('categorie_incident', i.categorie)
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Statut(FamilleStatut.incident, 'statut_incident', i.statut),
                ],
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Text(
                i.titre ?? 'Signalement',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppTheme.espaceXs),
              Text(
                '${i.reference ?? ''} · ${dateHeure(i.creeLe)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Avancement',
          children: [
            _EtapeIncident(
              titre: 'Signalé',
              date: dateHeure(i.creeLe),
              faite: true,
            ),
            _EtapeIncident(
              titre: 'Pris en charge',
              date: i.analyseLe == null ? null : dateHeure(i.analyseLe),
              faite: i.analyseLe != null,
            ),
            _EtapeIncident(
              titre: i.motifRejet != null ? 'Rejeté' : 'Résolu',
              date: i.resoluLe == null ? null : dateHeure(i.resoluLe),
              faite: i.resoluLe != null || i.motifRejet != null,
              derniere: true,
            ),
          ],
        ),
        if (i.motifRejet != null) ...[
          const SizedBox(height: AppTheme.espaceLg),
          Encadre('Motif du rejet : ${i.motifRejet}', ton: TonStatut.danger),
        ],
        if ((i.description ?? '').isNotEmpty) ...[
          const SizedBox(height: AppTheme.espaceLg),
          Section(
            titre: 'Description',
            children: [
              Text(
                i.description!,
                style: TextStyle(color: p.texte, height: 1.4),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Photos et vidéos',
          children: [
            if (i.pieces.isEmpty)
              Text(
                'Aucune pièce jointe pour le moment.',
                style: TextStyle(color: p.texteSecondaire),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: AppTheme.espaceSm,
                crossAxisSpacing: AppTheme.espaceSm,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (final d in i.pieces) VignettePiece(d)],
              ),
            if (i.ouvert) ...[
              const SizedBox(height: AppTheme.espaceMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPhoto,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                      label: const Text('Photo'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.espaceSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onVideo,
                      icon: const Icon(Icons.videocam_outlined, size: 20),
                      label: const Text('Vidéo'),
                    ),
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
                Ligne(
                  w.titre ?? 'Travaux',
                  null,
                  widget: Statut(
                    FamilleStatut.travaux,
                    'statut_travaux',
                    w.statut,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Étape de l'avancement : pastille reliée à la suivante.
class _EtapeIncident extends StatelessWidget {
  final String titre;
  final String? date;
  final bool faite;
  final bool derniere;
  const _EtapeIncident({
    required this.titre,
    required this.date,
    required this.faite,
    this.derniere = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: faite ? cs.primary : p.surfaceAlt,
                child: faite
                    ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                    : null,
              ),
              if (!derniere)
                Expanded(
                  child: Container(
                    width: 2,
                    color: faite ? cs.primary : p.bordure,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.espaceMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: derniere ? 0 : AppTheme.espaceLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: TextStyle(
                      color: faite ? p.texte : p.texteSecondaire,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (date != null)
                    Text(
                      date!,
                      style: TextStyle(color: p.texteSecondaire, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
