import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/account/domain/usecases/photo_profil.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/injection_container.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';

/// Dernière photo chargée, en mémoire seulement : tous les avatars la partagent.
String? _clePhoto;
Future<Uint8List?>? _photoChargee;

Future<Uint8List?> _photo(String cle) {
  if (_clePhoto == cle && _photoChargee != null) return _photoChargee!;
  _clePhoto = cle;
  return _photoChargee = sl<LirePhotoProfil>()().then((r) {
    final octets = r.fold((_) => null, (o) => o);
    // Échec : un prochain affichage réessaiera.
    if (octets == null && _clePhoto == cle) _photoChargee = null;
    return octets;
  });
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
    final version = u?.photoVersion;
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
          child: version == null
              ? initiales
              : FutureBuilder<Uint8List?>(
                  key: ValueKey('${u?.id}-$version'),
                  future: _photo('${u?.id}-$version'),
                  builder: (context, s) {
                    final octets = s.data;
                    if (octets == null) return initiales;
                    return Image.memory(
                      octets,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => initiales,
                    );
                  },
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

  Future<void> _modifier(BuildContext context) async {
    final existante =
        context.read<AuthBloc>().state.compte?.utilisateur.photoVersion != null;
    if (!existante) return _choisir(context);
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
    if (action == 'changer') return _choisir(context);
    if (action == 'supprimer') {
      final r = await sl<SupprimerPhotoProfil>()();
      if (context.mounted) _appliquer(context, r);
    }
  }

  Future<void> _choisir(BuildContext context) async {
    final photo = await choisirPhoto(context);
    if (photo == null || !context.mounted) return;
    final r = await sl<EnvoyerPhotoProfil>()(photo.path);
    // La copie laissée par le sélecteur de photos ne reste pas sur le téléphone.
    try {
      await File(photo.path).delete();
    } on FileSystemException {
      // Déjà retirée par le système.
    }
    if (context.mounted) _appliquer(context, r);
  }

  /// Le serveur fait foi : le compte rechargé indique la photo à afficher.
  void _appliquer(BuildContext context, Either<Failure, void> r) {
    if (!context.mounted) return;
    r.fold(
      (f) => afficherErreurApi(context, f),
      (_) => context.read<AuthBloc>().add(CompteRechargeDemande()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = context.select((AuthBloc b) => b.state.compte?.utilisateur.id);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: id == null ? null : () => _modifier(context),
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
