import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Choisit une photo. La permission n'est demandée qu'à ce moment (§ 33, CNIL) ;
/// l'image est compressée côté téléphone avant l'envoi (§ 37).
Future<XFile?> choisirPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
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
  if (source == null) return null;
  return ImagePicker().pickImage(
      source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 80);
}
