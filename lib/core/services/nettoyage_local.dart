import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/utils/fichier_temporaire.dart';

/// Toutes les données sont au backend : efface ce que les anciennes versions ont
/// laissé sur le téléphone (cache, file hors ligne, photos) et les fichiers
/// temporaires restants. Le jeton de session n'est pas touché.
Future<void> nettoyerStockageLocal({FlutterSecureStorage? coffre}) async {
  Future<void> etape(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Nettoyage du stockage local incomplet : $e');
    }
  }

  await etape(() async => (await SharedPreferences.getInstance()).clear());
  await etape(
    () => (coffre ?? const FlutterSecureStorage()).delete(
      key: 'gi.cle_donnees_locales',
    ),
  );
  await etape(viderFichiersTemporaires);
  await etape(() async {
    final temporaire = await getTemporaryDirectory();
    final documents = await getApplicationDocumentsDirectory();
    for (final (dossier, motif) in [
      (temporaire, RegExp(r'^(video_|rapport-).*')),
      (documents, RegExp(r'^photo_profil_.*\.jpg$')),
    ]) {
      await for (final e in dossier.list()) {
        final nom = e.uri.pathSegments.last;
        if (e is File && motif.hasMatch(nom)) await e.delete();
      }
    }
  });
}
