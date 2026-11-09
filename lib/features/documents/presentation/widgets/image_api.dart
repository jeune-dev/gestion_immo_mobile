import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either, Right;
import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/cache_images.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/telecharger_document.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/video_api.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Image servie par l'API (miniature d'abord, § 37) : chargée avec le jeton.
class ImageApi extends StatefulWidget {
  final String documentId;
  final String taille;
  final BoxFit fit;
  const ImageApi(
    this.documentId, {
    super.key,
    this.taille = 'miniature',
    this.fit = BoxFit.cover,
  });

  @override
  State<ImageApi> createState() => _ImageApiState();
}

class _ImageApiState extends State<ImageApi> {
  late Future<Either<Failure, Uint8List>> _image = _charger();

  /// Depuis le cache mémoire si l'image est déjà venue, sinon depuis l'API.
  Future<Either<Failure, Uint8List>> _charger() async {
    final cle = '${widget.documentId}|${widget.taille}';
    final cache = sl<CacheImages>();
    final connue = cache.lire(cle);
    if (connue != null) return Right(connue);
    final r = await sl<TelechargerDocument>()(
      widget.documentId,
      taille: widget.taille,
    );
    r.fold((_) {}, (octets) => cache.ecrire(cle, octets));
    return r;
  }

  @override
  void didUpdateWidget(covariant ImageApi ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.documentId != widget.documentId ||
        ancien.taille != widget.taille) {
      _image = _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, Uint8List>>(
      future: _image,
      builder: (context, s) {
        final octets = s.data?.fold((_) => null, (o) => o);
        if (octets != null) {
          return Image.memory(octets, fit: widget.fit, gaplessPlayback: true);
        }
        return Container(
          color: context.palette.surfaceAlt,
          child: Center(
            child: s.data?.isLeft() ?? false
                ? const Icon(Icons.broken_image_outlined)
                : const CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

void afficherImage(BuildContext context, String documentId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(flexibleSpace: const FondMarque()),
        body: InteractiveViewer(
          child: Center(
            child: ImageApi(
              documentId,
              taille: 'originale',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Ouvre un document stocké : image en plein écran, vidéo, PDF dans le lecteur.
void ouvrirDocument(BuildContext context, DocumentApp doc) {
  if (doc.estImage) return afficherImage(context, doc.id);
  if (doc.estVideo) return ouvrirVideo(context, doc);
  ouvrirFichierDocument(context, doc.id, doc.nomOrigine ?? 'document.pdf');
}

/// PDF d'un document (contrat, justificatif…) ouvert dans le lecteur du téléphone.
void ouvrirFichierDocument(
  BuildContext context,
  String documentId,
  String nomFichier, {
  bool partager = false,
}) => ouvrirPdf(
  context,
  () => sl<TelechargerDocument>()(documentId),
  nomFichier,
  partager: partager,
);
