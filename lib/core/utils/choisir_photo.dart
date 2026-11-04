import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Choisit une photo. La permission n'est demandée qu'à ce moment (§ 33, CNIL) ;
/// l'image est compressée côté téléphone avant l'envoi (§ 37).
Future<XFile?> choisirPhoto(BuildContext context) async {
  final source = await _choisirSource(context);
  if (source == null) return null;
  return ImagePicker().pickImage(
    source: source,
    maxWidth: 2000,
    maxHeight: 2000,
    imageQuality: 80,
  );
}

/// Choisit plusieurs photos : une seule à l'appareil photo, jusqu'à [max] dans
/// la galerie. Liste vide si l'utilisateur renonce.
Future<List<XFile>> choisirPhotos(BuildContext context, {int max = 10}) async {
  final source = await _choisirSource(context);
  if (source == null) return const [];
  if (source == ImageSource.gallery) {
    return ImagePicker().pickMultiImage(
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 80,
      limit: max,
    );
  }
  final photo = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2000,
    maxHeight: 2000,
    imageQuality: 80,
  );
  return [?photo];
}

Future<ImageSource?> _choisirSource(
  BuildContext context, {
  bool video = false,
}) => showModalBottomSheet<ImageSource>(
  context: context,
  builder: (ctx) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            video ? Icons.videocam_outlined : Icons.photo_camera_outlined,
          ),
          title: Text(video ? 'Filmer une vidéo' : 'Prendre une photo'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Choisir dans la galerie'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ],
    ),
  ),
);

/// Filme ou choisit une vidéo (une minute au plus à la caméra).
Future<XFile?> choisirVideo(BuildContext context) async {
  final source = await _choisirSource(context, video: true);
  if (source == null) return null;
  return ImagePicker().pickVideo(
    source: source,
    maxDuration: const Duration(seconds: 60),
  );
}
