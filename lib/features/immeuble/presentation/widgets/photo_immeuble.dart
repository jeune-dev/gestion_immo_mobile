import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/ajouter_photo_document.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/get_documents.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';

String _cleCouverture(String immeubleId) => 'couverture_immeuble_$immeubleId';

/// Photo de couverture choisie pour un immeuble (enregistrée sur ce téléphone).
Future<String?> lireCouvertureImmeuble(String immeubleId) async =>
    (await SharedPreferences.getInstance()).getString(
      _cleCouverture(immeubleId),
    );

Future<void> definirCouvertureImmeuble(
  String immeubleId,
  String documentId,
) async => (await SharedPreferences.getInstance()).setString(
  _cleCouverture(immeubleId),
  documentId,
);

/// Photo de couverture d'un immeuble : celle enregistrée sur le serveur, sinon
/// celle choisie sur ce téléphone, sinon la plus récente (`null` sans photo).
Future<DocumentApp?> _photoCouverture(
  String immeubleId,
  String? couvertureServeur,
) async {
  final r = await sl<GetDocuments>()(type: 'building', id: immeubleId);
  final photos = r.fold(
    (_) => <DocumentApp>[],
    (page) => page.items.where((d) => d.estImage).toList(),
  );
  if (photos.isEmpty) return null;
  final choisie = couvertureServeur ?? await lireCouvertureImmeuble(immeubleId);
  final trouvee = photos.where((d) => d.id == choisie).firstOrNull;
  if (trouvee != null) return trouvee;
  photos.sort((a, b) => (b.creeLe ?? '').compareTo(a.creeLe ?? ''));
  return photos.first;
}

/// Vignette d'un immeuble dans une liste : sa photo, sinon une icône.
class VignetteImmeuble extends StatefulWidget {
  final String immeubleId;
  final String? couvertureId;
  final double taille;
  const VignetteImmeuble({
    super.key,
    required this.immeubleId,
    this.couvertureId,
    this.taille = 72,
  });

  @override
  State<VignetteImmeuble> createState() => _VignetteImmeubleState();
}

class _VignetteImmeubleState extends State<VignetteImmeuble> {
  late final Future<DocumentApp?> _photo = _photoCouverture(
    widget.immeubleId,
    widget.couvertureId,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.rayon),
      child: SizedBox.square(
        dimension: widget.taille,
        child: FutureBuilder<DocumentApp?>(
          future: _photo,
          builder: (context, s) {
            final photo = s.data;
            if (photo != null) return ImageApi(photo.id);
            return ColoredBox(
              color: p.primaireTeinte,
              child: Icon(
                Icons.apartment,
                color: Theme.of(context).colorScheme.primary,
                size: widget.taille * 0.45,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Grande photo en tête de la fiche d'un immeuble, avec l'ajout de photos.
class CouvertureImmeuble extends StatefulWidget {
  final String immeubleId;
  final String? couvertureId;

  /// Appelé après l'ajout de photos.
  final VoidCallback? onAjout;
  const CouvertureImmeuble({
    super.key,
    required this.immeubleId,
    this.couvertureId,
    this.onAjout,
  });

  @override
  State<CouvertureImmeuble> createState() => _CouvertureImmeubleState();
}

class _CouvertureImmeubleState extends State<CouvertureImmeuble> {
  late Future<DocumentApp?> _photo = _photoCouverture(
    widget.immeubleId,
    widget.couvertureId,
  );
  bool _envoi = false;

  Future<void> _ajouter() async {
    final photos = await choisirPhotos(context);
    if (photos.isEmpty || !mounted) return;
    setState(() => _envoi = true);
    for (final photo in photos) {
      final r = await sl<AjouterPhotoDocument>()(
        type: 'building',
        id: widget.immeubleId,
        chemin: photo.path,
      );
      if (!mounted) return;
      if (r.isLeft()) {
        r.fold((f) => afficherErreurApi(context, f), (_) {});
        break;
      }
    }
    _photo = _photoCouverture(widget.immeubleId, widget.couvertureId);
    setState(() => _envoi = false);
    widget.onAjout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.rayonCarte),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: FutureBuilder<DocumentApp?>(
          future: _photo,
          builder: (context, s) {
            final photo = s.data;
            if (s.connectionState != ConnectionState.done) {
              return ColoredBox(
                color: p.surfaceAlt,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  GestureDetector(
                    onTap: () => afficherImage(context, photo.id),
                    child: ImageApi(photo.id, taille: 'originale'),
                  )
                else
                  ColoredBox(
                    color: p.primaireTeinte,
                    child: Icon(Icons.apartment, color: cs.primary, size: 56),
                  ),
                Positioned(
                  right: AppTheme.espaceMd,
                  bottom: AppTheme.espaceMd,
                  child: FilledButton.tonalIcon(
                    onPressed: _envoi ? null : _ajouter,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.espaceMd,
                      ),
                    ),
                    icon: _envoi
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Ajouter des photos'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
