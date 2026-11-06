import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/formulaire_appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/tuile_appartement.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/usecases/modifier_immeuble.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/bloc/immeuble_bloc.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/bloc/immeuble_event.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/bloc/immeuble_state.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/formulaire_immeuble.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/photo_immeuble.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

class ImmeubleDetailPage extends StatelessWidget {
  final String id;
  const ImmeubleDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ImmeubleBloc>()..add(LoadImmeuble(id)),
      child: BlocConsumer<ImmeubleBloc, ImmeubleState>(
        listener: (context, state) {
          if (state is ImmeubleSuccess) {
            afficherSucces(context, state.message);
          } else if (state is ImmeubleActionError) {
            afficherErreurApi(context, state.failure);
          } else if (state is ImmeubleSupprime) {
            afficherSucces(context, state.message);
            Navigator.of(context).pop(true);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is ImmeubleInitial ||
            state is ImmeubleLoading ||
            state is ImmeubleLoaded ||
            state is ImmeubleError,
        builder: (context, state) {
          if (state is ImmeubleLoaded) {
            return _VueFiche(id: id, fiche: state.fiche);
          }
          return VueChargement(
            titre: 'Immeuble',
            failure: state is ImmeubleError ? state.failure : null,
            onReessayer: () =>
                context.read<ImmeubleBloc>().add(LoadImmeuble(id)),
          );
        },
      ),
    );
  }
}

class _VueFiche extends StatefulWidget {
  final String id;
  final FicheImmeuble fiche;
  const _VueFiche({required this.id, required this.fiche});

  @override
  State<_VueFiche> createState() => _VueFicheState();
}

class _VueFicheState extends State<_VueFiche> {
  /// Change après l'ajout de photos depuis la couverture : recharge les documents.
  int _versionPhotos = 0;

  /// Change après un ajout, une suppression ou un choix : recharge la couverture.
  int _versionCouverture = 0;
  late String? _couvertureId = widget.fiche.immeuble.couvertureId;

  Future<void> _choisirCouverture(DocumentApp photo) async {
    final r = await di.sl<ModifierImmeuble>()(widget.id, {
      'cover_document_id': photo.id,
    });
    if (!mounted) return;
    r.fold((f) => afficherErreurApi(context, f), (_) {
      setState(() {
        _couvertureId = photo.id;
        _versionCouverture++;
      });
      afficherSucces(context, 'Photo de couverture modifiée');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ImmeubleBloc>();
    final id = widget.id;
    final b = widget.fiche.immeuble;
    final apps = widget.fiche.appartements;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(b.nom),
        actions: [
          MenuActions(
            actions: [
              (
                'Supprimer',
                () async {
                  final ok = await confirmer(
                    context,
                    titre: 'Supprimer l’immeuble',
                    message:
                        'Seul un immeuble sans appartement peut être supprimé.',
                    action: 'Supprimer',
                    danger: true,
                  );
                  if (ok != null) bloc.add(SupprimerImmeubleEvent(id));
                },
                true,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await formulaireAppartement(context, immeuble: b) != null) {
            bloc.add(RafraichirImmeuble(id));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Appartement'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          bloc.add(RafraichirImmeuble(id));
          setState(() {
            _versionPhotos++;
            _versionCouverture++;
          });
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            CouvertureImmeuble(
              key: ValueKey('couverture-$_versionCouverture'),
              immeubleId: id,
              couvertureId: _couvertureId,
              onAjout: () => setState(() => _versionPhotos++),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Informations',
              children: [
                Ligne('Adresse', b.adresse),
                Ligne('Quartier', b.quartier),
                Ligne('Ville', b.ville),
                Ligne(
                  "Nombre d'étages",
                  b.nbEtages == null ? null : '${b.nbEtages}',
                ),
                Ligne(
                  'Appartements',
                  '${apps.length}${b.nbAppartementsPrevus != null ? ' / ${b.nbAppartementsPrevus} prévus' : ''}',
                ),
                Ligne('Occupés', '${apps.where((a) => a.occupe).length}'),
                Ligne(
                  'Loyers mensuels',
                  montant(apps.fold<int>(0, (t, a) => t + (a.loyer ?? 0))),
                ),
                if ((b.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppTheme.espaceSm),
                  Text(b.description!),
                ],
                const SizedBox(height: AppTheme.espaceLg),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (await formulaireImmeuble(context, existant: b) !=
                        null) {
                      bloc.add(RafraichirImmeuble(id));
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier les infos'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Appartements',
              padding: false,
              children: apps.isEmpty
                  ? [const Vide('Aucun appartement dans cet immeuble')]
                  : [
                      for (final a in apps)
                        TuileAppartement(
                          a: a,
                          onRetour: () => bloc.add(RafraichirImmeuble(id)),
                        ),
                    ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            SectionDocuments(
              key: ValueKey('documents-$_versionPhotos'),
              type: 'building',
              id: id,
              couvertureId: _couvertureId,
              onCouverture: _choisirCouverture,
              onChangement: () => setState(() => _versionCouverture++),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre la fiche d'un immeuble.
Future<void> ouvrirImmeuble(BuildContext context, String id) =>
    ouvrir(context, ImmeubleDetailPage(id: id));
