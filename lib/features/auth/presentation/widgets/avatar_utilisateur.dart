import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';

/// Change à chaque modification de la photo : tous les avatars se redessinent.
final _versionPhoto = ValueNotifier<int>(0);

/// Fichier de la photo de profil d'un compte (enregistrée sur ce téléphone :
/// l'API ne stocke pas encore de photo d'utilisateur).
Future<File?> _fichierPhoto(String utilisateurId) async {
  try {
    final dossier = await getApplicationDocumentsDirectory();
    return File('${dossier.path}/photo_profil_$utilisateurId.jpg');
  } on Exception {
    return null;
  }
}

Future<File?> _photoExistante(String? utilisateurId) async {
  if (utilisateurId == null) return null;
  final fichier = await _fichierPhoto(utilisateurId);
  return fichier != null && await fichier.exists() ? fichier : null;
}

Future<void> _rafraichir(File fichier) async {
  await FileImage(fichier).evict();
  _versionPhoto.value++;
}

/// Photo de profil du compte connecté, ou ses initiales s'il n'en a pas
/// (ou si elle ne se charge pas).
class AvatarUtilisateur extends StatelessWidget {
  final double taille;
  final VoidCallback? onTap;

  /// Sur le fond bleu de la marque : pastille blanche. Sinon, pastille teintée.
  final bool surMarque;
  const AvatarUtilisateur({
    super.key,
    this.taille = 36,
    this.onTap,
    this.surMarque = true,
  });

  @override
  Widget build(BuildContext context) {
    final u = context.select((AuthBloc b) => b.state.compte?.utilisateur);
    final cs = Theme.of(context).colorScheme;
    final initiales = Center(
      child: Text(
        u?.initiales ?? '',
        style: TextStyle(
          color: surMarque ? AppColors.primaire : cs.primary,
          fontSize: taille * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final url = u?.photoUrl;
    final distante = url == null || url.isEmpty
        ? initiales
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => initiales,
          );
    return Semantics(
      label: u?.nomComplet,
      image: true,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: taille,
          height: taille,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: surMarque ? Colors.white : context.palette.primaireTeinte,
            shape: BoxShape.circle,
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: _versionPhoto,
            builder: (context, version, _) => FutureBuilder<File?>(
              key: ValueKey('${u?.id}-$version'),
              future: _photoExistante(u?.id),
              builder: (context, s) {
                final fichier = s.data;
                if (fichier == null) return distante;
                return Image.file(
                  fichier,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => distante,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Grand avatar du formulaire de profil : toucher permet de choisir, changer ou
/// supprimer la photo.
class EditeurPhotoProfil extends StatelessWidget {
  const EditeurPhotoProfil({super.key});

  Future<void> _modifier(BuildContext context, String utilisateurId) async {
    final existante = await _photoExistante(utilisateurId);
    if (!context.mounted) return;
    if (existante == null) return _choisir(context, utilisateurId);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined),
              title: const Text('Changer la photo'),
              onTap: () => Navigator.pop(ctx, 'changer'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                'Supprimer la photo',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.pop(ctx, 'supprimer'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'changer') return _choisir(context, utilisateurId);
    if (action == 'supprimer') {
      await existante.delete();
      await _rafraichir(existante);
    }
  }

  Future<void> _choisir(BuildContext context, String utilisateurId) async {
    final photo = await choisirPhoto(context);
    if (photo == null) return;
    final fichier = await _fichierPhoto(utilisateurId);
    if (fichier == null) {
      if (context.mounted) {
        afficherErreur(context, "La photo n'a pas pu être enregistrée.");
      }
      return;
    }
    await File(photo.path).copy(fichier.path);
    await _rafraichir(fichier);
  }

  @override
  Widget build(BuildContext context) {
    final id = context.select((AuthBloc b) => b.state.compte?.utilisateur.id);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: id == null ? null : () => _modifier(context, id),
        child: SizedBox.square(
          dimension: 104,
          child: Stack(
            children: [
              const Center(
                child: AvatarUtilisateur(taille: 96, surMarque: false),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 18,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
