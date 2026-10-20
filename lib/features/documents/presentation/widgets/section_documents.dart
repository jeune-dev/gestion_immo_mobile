import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/bloc/documents_bloc.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/bloc/documents_event.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/bloc/documents_state.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';

/// Documents et photos rattachés à une entité (immeuble, appartement, locataire, bail, artisan).
class SectionDocuments extends StatelessWidget {
  final String type;
  final String id;
  final String titre;

  /// L'ajout direct (`POST /documents`) n'existe que pour immeuble, appartement,
  /// locataire, bail et artisan ; les autres entités ont leur propre route.
  final bool ajout;

  const SectionDocuments(
      {super.key,
      required this.type,
      required this.id,
      this.titre = 'Documents et photos',
      this.ajout = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('$type/$id'),
      create: (_) => sl<DocumentsBloc>()..add(LoadDocuments(type, id)),
      child: _Section(titre: titre, ajout: ajout, type: type, id: id),
    );
  }
}

class _Section extends StatelessWidget {
  final String titre;
  final bool ajout;
  final String type;
  final String id;
  const _Section({
    required this.titre,
    required this.ajout,
    required this.type,
    required this.id,
  });

  /// Catégories que l'API laisse supprimer (les pièces probantes — contrat,
  /// quittance, état des lieux, reçu — restent : 409 DOCUMENT_PROTEGE).
  static const _supprimables = [
    'photo',
    'piece_identite',
    'autre',
    'justificatif',
    'facture'
  ];

  /// Seuls les documents d'un locataire ou d'un bail concernent un locataire
  /// et peuvent lui être partagés.
  bool get _partageable => type == 'tenant' || type == 'lease';

  Future<void> _ajouter(BuildContext context) async {
    final bloc = context.read<DocumentsBloc>();
    final photo = await choisirPhoto(context);
    if (photo != null) {
      bloc.add(AjouterPhotoDocumentEvent(type, id, photo.path));
    }
  }

  Future<void> _supprimer(BuildContext context, DocumentApp d) async {
    final bloc = context.read<DocumentsBloc>();
    final ok = await confirmer(
      context,
      titre: 'Supprimer le document',
      message: 'Le document sera définitivement retiré.',
      action: 'Supprimer',
      danger: true,
    );
    if (ok != null) bloc.add(SupprimerDocumentEvent(type, id, d.id));
  }

  Future<void> _actions(BuildContext context, DocumentApp d) async {
    final bloc = context.read<DocumentsBloc>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Ouvrir'),
              onTap: () {
                Navigator.pop(ctx);
                ouvrirDocument(context, d);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Partager un lien temporaire'),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(GetLienDocumentEvent(d.id));
              },
            ),
            if (ajout && _partageable)
              SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: const Text('Visible par le locataire'),
                value: d.visibleLocataire,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  bloc.add(ChangerVisibiliteDocumentEvent(type, id, d.id, v));
                },
              ),
            if (ajout && _supprimables.contains(d.categorie))
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Supprimer',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _supprimer(context, d);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _partager(BuildContext context, LienDocument lien) async {
    if (!lien.partageable) {
      return afficherErreur(context,
          'Lien temporaire indisponible pour ce document : ouvrez-le puis partagez le fichier.');
    }
    final minutes = lien.expireDansSecondes == null
        ? null
        : (lien.expireDansSecondes! / 60).round();
    await SharePlus.instance.share(ShareParams(
        text: lien.url,
        subject:
            'Document${minutes != null ? ' (lien valable $minutes min)' : ''}'));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentsBloc, DocumentsState>(
      listener: (context, state) {
        if (state is DocumentsError) {
          afficherErreurApi(context, state.failure);
        } else if (state is DocumentsSuccess) {
          afficherSucces(context, state.message);
        } else if (state is LienDocumentLoaded) {
          _partager(context, state.lien);
        }
      },
      // Seule la liste lue redessine la section (les messages sont ponctuels).
      buildWhen: (_, state) =>
          state is DocumentsInitial || state is DocumentsLoaded,
      builder: (context, state) => _buildSection(
        context,
        state is DocumentsLoaded ? state.documents : null,
      ),
    );
  }

  Widget _buildSection(BuildContext context, List<DocumentApp>? documents) {
    return Section(
      titre: titre,
      action: ajout
          ? IconButton(
              tooltip: 'Ajouter une photo',
              onPressed: () => _ajouter(context),
              icon: const Icon(Icons.add_a_photo_outlined))
          : null,
      children: [
        if (documents == null)
          const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (documents.isEmpty)
          Text('Aucun document',
              style: TextStyle(color: context.palette.texteSecondaire))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppTheme.espaceSm,
                runSpacing: AppTheme.espaceSm,
                children: [
                  for (final d in documents)
                    InkWell(
                      onTap: () => ouvrirDocument(context, d),
                      onLongPress: () => _actions(context, d),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.rayon),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: d.estImage && d.aMiniature
                              ? ImageApi(d.id)
                              : Container(
                                  color: context.palette.surfaceAlt,
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.description_outlined),
                                      Text(
                                        refs.libelle(
                                            'categorie_document', d.categorie),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      Text(date(d.creeLe),
                                          style: const TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Text(
                'Appui long sur un document : partager, gérer, supprimer.',
                style: TextStyle(
                    fontSize: 12, color: context.palette.texteSecondaire),
              ),
            ],
          ),
      ],
    );
  }
}
