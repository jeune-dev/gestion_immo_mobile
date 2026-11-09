import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/depense/presentation/widgets/formulaires_depense.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/entities/travaux.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/bloc/travaux_bloc.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/bloc/travaux_event.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/bloc/travaux_state.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/widgets/formulaires_travaux.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Fiche d'un chantier (§ 18–19) : statut historisé, photos avant / pendant / après, dépenses.
class TravauxDetailPage extends StatelessWidget {
  final String id;
  const TravauxDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<TravauxBloc>()..add(LoadTravaux(id)),
      child: BlocConsumer<TravauxBloc, TravauxState>(
        listener: (context, state) {
          if (state is TravauxSuccess) {
            afficherSucces(context, state.message);
          } else if (state is TravauxActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is TravauxInitial ||
            state is TravauxLoading ||
            state is TravauxLoaded ||
            state is TravauxError,
        builder: (context, state) {
          if (state is TravauxLoaded) {
            return _buildFiche(context, state.travaux);
          }
          return VueChargement(
            titre: 'Travaux',
            failure: state is TravauxError ? state.failure : null,
            onReessayer: () => context.read<TravauxBloc>().add(LoadTravaux(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, Travaux t) {
    final bloc = context.read<TravauxBloc>();
    Future<void> photo(String phase) async {
      final p = await choisirPhoto(context);
      if (p != null) bloc.add(AjouterPhotoTravauxEvent(id, phase, p.path));
    }

    Future<void> retirer(PhotoTravaux p) async {
      final ok = await confirmer(
        context,
        titre: 'Retirer la photo',
        message: 'La photo sera supprimée du chantier.',
        action: 'Retirer',
        danger: true,
      );
      if (ok != null) bloc.add(SupprimerPhotoTravauxEvent(id, p.id));
    }

    final suivants = transitionsTravaux[t.statut] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(t.reference ?? 'Travaux'),
        actions: [
          if (!t.ferme)
            MenuActions(
              actions: [
                (
                  'Modifier',
                  () async {
                    if (await formulaireTravaux(context, existant: t) != null) {
                      bloc.add(RafraichirTravaux(id));
                    }
                  },
                  false,
                ),
                (
                  'Ajouter une dépense',
                  () async {
                    if (await nouvelleDepense(
                      context,
                      travauxId: t.id,
                      travauxTitre: t.titre,
                    )) {
                      bloc.add(RafraichirTravaux(id));
                    }
                  },
                  false,
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => bloc.add(RafraichirTravaux(id)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EnTeteFiche(
              surtitre: refs.libelle('categorie_travaux', t.categorie),
              titre: t.titre ?? 'Travaux',
              detail: t.immeubleNom,
              statut: Statut(FamilleStatut.travaux, 'statut_travaux', t.statut),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            _informations(t),
            if (suivants.isNotEmpty) ...[
              const SizedBox(height: AppTheme.espaceLg),
              _transitions(context, t, suivants),
            ],
            const SizedBox(height: AppTheme.espaceLg),
            for (final phase in ['avant', 'pendant', 'apres']) ...[
              _PhotosChantier(
                travaux: t,
                phase: phase,
                onAjouter: () => photo(phase),
                onRetirer: retirer,
              ),
              const SizedBox(height: AppTheme.espaceSm),
            ],
            const SizedBox(height: AppTheme.espaceSm),
            _depenses(t),
            const SizedBox(height: AppTheme.espaceLg),
            _historique(t),
          ],
        ),
      ),
    );
  }

  Widget _informations(Travaux t) => Section(
    titre: 'Informations',
    children: [
      Ligne('Immeuble', t.immeubleNom ?? ''),
      if (t.appartementNumero != null)
        Ligne('Appartement', t.appartementNumero),
      Ligne('Catégorie', refs.libelle('categorie_travaux', t.categorie)),
      Ligne(
        'Priorité',
        null,
        widget: Statut(FamilleStatut.priorite, 'priorite', t.priorite),
      ),
      Ligne('Artisan', t.artisanNom),
      Ligne('Prévu le', date(t.prevuLe)),
      Ligne('Coût estimé', montant(t.coutEstime)),
      Ligne('Coût réel', montant(t.coutReel)),
      Ligne('Dépenses liées', montant(t.totalDepenses)),
      if (t.incidentReference != null) Ligne('Incident', t.incidentReference),
      if (t.description != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(t.description!),
        ),
    ],
  );

  /// Passages possibles vers les statuts suivants (§ 18).
  Widget _transitions(BuildContext context, Travaux t, List<String> suivants) {
    final bloc = context.read<TravauxBloc>();
    Future<void> changer(String statut) async {
      if (await changerStatutTravaux(context, t, statut)) {
        bloc.add(RafraichirTravaux(id));
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in suivants)
          s == 'annule'
              ? TextButton(
                  onPressed: () => changer(s),
                  child: const Text('Annuler les travaux'),
                )
              : OutlinedButton(
                  onPressed: () => changer(s),
                  child: Text('→ ${refs.libelle('statut_travaux', s)}'),
                ),
      ],
    );
  }

  Widget _depenses(Travaux t) => Section(
    titre: 'Dépenses',
    padding: false,
    children: [
      if (t.depenses.isEmpty)
        const ListTile(title: Text('Aucune dépense liée')),
      for (final d in t.depenses)
        TuileOption(
          icone: Icons.receipt_long_outlined,
          titre: d.libelle,
          detail: date(d.date),
          fin: Montant(d.montant),
        ),
    ],
  );

  Widget _historique(Travaux t) => Section(
    titre: 'Historique',
    padding: false,
    children: [
      for (final e in t.historique.reversed)
        TuileOption(
          icone: Icons.receipt_long_outlined,
          titre: refs.libelle('statut_travaux', e.statut),
          detail:
              '${dateHeure(e.date)}${e.commentaire != null ? ' · ${e.commentaire}' : ''}',
          fin: const SizedBox.shrink(),
        ),
    ],
  );
}

/// Photos d'une phase du chantier (avant, pendant, après) : toucher pour
/// agrandir, appui long pour retirer tant que le chantier est ouvert.
class _PhotosChantier extends StatelessWidget {
  final Travaux travaux;
  final String phase;
  final VoidCallback onAjouter;
  final void Function(PhotoTravaux photo) onRetirer;

  const _PhotosChantier({
    required this.travaux,
    required this.phase,
    required this.onAjouter,
    required this.onRetirer,
  });

  @override
  Widget build(BuildContext context) => Section(
    titre: 'Photos ${refs.libelle('phase_photo', phase).toLowerCase()}',
    action: travaux.ferme
        ? null
        : IconButton(
            tooltip: 'Ajouter',
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: onAjouter,
          ),
    children: [
      if ((travaux.photos[phase] ?? const []).isEmpty)
        Text(
          'Aucune photo',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        )
      else
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in travaux.photos[phase]!)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => afficherImage(context, p.document.id),
                    // Chantier terminé ou annulé : les photos sont des preuves, l'API refuse leur retrait
                    onLongPress: travaux.ferme ? null : () => onRetirer(p),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.rayon),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: ImageApi(p.document.id),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

/// Raccourci réutilisé par l'écran des incidents.
Future<void> ouvrirTravaux(BuildContext context, String id) =>
    ouvrir(context, TravauxDetailPage(id: id));
