import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/entities/artisan.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/bloc/artisan_bloc.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/bloc/artisan_event.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/bloc/artisan_state.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/widgets/formulaire_artisan.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Fiche d'un artisan (§ 24).
class ArtisanDetailPage extends StatelessWidget {
  final String id;
  const ArtisanDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ArtisanBloc>()..add(LoadArtisan(id)),
      child: BlocConsumer<ArtisanBloc, ArtisanState>(
        listener: (context, state) {
          if (state is ArtisanSuccess) {
            afficherSucces(context, state.message);
          } else if (state is ArtisanActionError) {
            afficherErreurApi(context, state.failure);
          } else if (state is ArtisanSupprime) {
            afficherSucces(context, state.message);
            Navigator.of(context).pop(true);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is ArtisanInitial ||
            state is ArtisanLoading ||
            state is ArtisanLoaded ||
            state is ArtisanError,
        builder: (context, state) {
          if (state is ArtisanLoaded) {
            return _buildFiche(context, state.artisan);
          }
          return VueChargement(
            titre: 'Artisan',
            failure: state is ArtisanError ? state.failure : null,
            onReessayer: () => context.read<ArtisanBloc>().add(LoadArtisan(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, Artisan a) {
    final bloc = context.read<ArtisanBloc>();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(a.nom),
        actions: [
          MenuActions(
            actions: [
              (
                'Modifier',
                () async {
                  if (await formulaireArtisan(context, existant: a) != null) {
                    bloc.add(RafraichirArtisan(id));
                  }
                },
                false,
              ),
              (
                a.actif ? 'Désactiver' : 'Réactiver',
                () => bloc.add(DefinirActiviteArtisanEvent(id, !a.actif)),
                false,
              ),
              (
                'Supprimer',
                () async {
                  final ok = await confirmer(
                    context,
                    titre: "Supprimer l'artisan",
                    message: 'Impossible tant qu’il a des travaux en cours.',
                    action: 'Supprimer',
                    danger: true,
                  );
                  if (ok != null) bloc.add(SupprimerArtisanEvent(id));
                },
                true,
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EnTeteFiche(
            surtitre: refs.libelle('metier_artisan', a.metier),
            titre: a.nom,
            detail:
                '${a.interventions} intervention(s) · ${montant(a.totalPaye)} payés',
            statut: a.actif ? null : const Pastille('Inactif'),
          ),
          const SizedBox(height: AppTheme.espaceLg),
          Section(
            titre: 'Coordonnées',
            children: [
              Ligne('Téléphone', a.telephone),
              Ligne('E-mail', a.email),
              if (a.notes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(a.notes!),
                ),
              if (a.telephone != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => appeler(context, a.telephone),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Appeler'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SectionDocuments(type: 'contractor', id: id),
        ],
      ),
    );
  }
}

/// Ouvre la fiche (utilisé par les listes).
Future<void> ouvrirArtisan(BuildContext context, String id) =>
    ouvrir(context, ArtisanDetailPage(id: id));
