import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gestion_immo_mobile/core/utils/fichier_temporaire.dart';
import 'package:video_player/video_player.dart';

import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/telecharger_document.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/injection_container.dart';

/// Fichier temporaire d'une vidéo de l'API, téléchargée avec le jeton : il
/// n'existe que le temps de l'affichage (le lecteur ne lit qu'un fichier).
/// `null` si la vidéo est indisponible.
Future<File?> _fichierVideo(DocumentApp doc) async {
  final extension = doc.mimeType == 'video/quicktime'
      ? 'mov'
      : doc.mimeType == 'video/webm'
      ? 'webm'
      : 'mp4';
  final r = await sl<TelechargerDocument>()(doc.id);
  final octets = r.fold((_) => null, (o) => o);
  if (octets == null) return null;
  return ecrireFichierTemporaire('video.$extension', octets);
}

/// Première image d'une vidéo, avec le bouton de lecture.
class ApercuVideo extends StatefulWidget {
  final DocumentApp doc;
  const ApercuVideo(this.doc, {super.key});

  @override
  State<ApercuVideo> createState() => _ApercuVideoState();
}

class _ApercuVideoState extends State<ApercuVideo> {
  VideoPlayerController? _video;
  File? _fichier;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _preparer();
  }

  Future<void> _preparer() async {
    try {
      final fichier = _fichier = await _fichierVideo(widget.doc);
      if (fichier != null) {
        final video = VideoPlayerController.file(fichier);
        await video.initialize();
        if (!mounted) {
          await video.dispose();
          await supprimerFichierTemporaire(fichier);
          return;
        }
        _video = video;
      }
    } on Exception {
      // Vidéo illisible : la tuile garde le bouton de lecture sur fond sombre.
    }
    if (mounted) setState(() => _chargement = false);
  }

  @override
  void dispose() {
    final video = _video;
    final fichier = _fichier;
    () async {
      await video?.dispose();
      if (fichier != null) await supprimerFichierTemporaire(fichier);
    }();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return ColoredBox(
      color: const Color(0xFF0B1B33),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: video.value.size.width,
                height: video.value.size.height,
                child: VideoPlayer(video),
              ),
            ),
          Center(
            child: _chargement
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0x99000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Vignette d'une pièce jointe : photo ou vidéo, ouverte au toucher.
class VignettePiece extends StatelessWidget {
  final DocumentApp doc;
  const VignettePiece(this.doc, {super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => ouvrirDocument(context, doc),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: doc.estVideo ? ApercuVideo(doc) : ImageApi(doc.id),
    ),
  );
}

/// Ouvre le lecteur plein écran.
void ouvrirVideo(BuildContext context, DocumentApp doc) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => LecteurVideoPage(doc: doc)));
}

class LecteurVideoPage extends StatefulWidget {
  final DocumentApp doc;
  const LecteurVideoPage({super.key, required this.doc});

  @override
  State<LecteurVideoPage> createState() => _LecteurVideoPageState();
}

class _LecteurVideoPageState extends State<LecteurVideoPage> {
  VideoPlayerController? _video;
  File? _fichier;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _preparer();
  }

  Future<void> _preparer() async {
    try {
      final fichier = _fichier = await _fichierVideo(widget.doc);
      if (fichier == null) throw const FileSystemException();
      final video = VideoPlayerController.file(fichier);
      await video.initialize();
      if (!mounted) {
        await video.dispose();
        await supprimerFichierTemporaire(fichier);
        return;
      }
      await video.play();
      setState(() => _video = video);
    } on Exception {
      if (!mounted) return;
      setState(() => _erreur = true);
      afficherErreur(context, 'Cette vidéo n’a pas pu être lue.');
    }
  }

  @override
  void dispose() {
    final video = _video;
    final fichier = _fichier;
    () async {
      await video?.dispose();
      if (fichier != null) await supprimerFichierTemporaire(fichier);
    }();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Vidéo'),
      ),
      body: video == null
          ? Center(
              child: _erreur
                  ? const Icon(
                      Icons.videocam_off_outlined,
                      color: Colors.white70,
                      size: 48,
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: video.value.aspectRatio,
                        child: VideoPlayer(video),
                      ),
                    ),
                  ),
                  VideoProgressIndicator(
                    video,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: video,
                    builder: (context, v, _) {
                      final fini = !v.isPlaying && v.position >= v.duration;
                      return IconButton(
                        iconSize: 44,
                        color: Colors.white,
                        tooltip: v.isPlaying ? 'Pause' : 'Lecture',
                        onPressed: () async {
                          if (v.isPlaying) return video.pause();
                          if (fini) await video.seekTo(Duration.zero);
                          await video.play();
                        },
                        icon: Icon(
                          v.isPlaying
                              ? Icons.pause_circle_filled
                              : fini
                              ? Icons.replay_circle_filled
                              : Icons.play_circle_filled,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
