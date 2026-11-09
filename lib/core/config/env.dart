import 'dart:io';

import 'package:flutter/foundation.dart';

/// Configuration de compilation : rien n'est lu dans un fichier embarqué, aucun
/// fichier de configuration n'est livré dans l'application.
///
/// URL de l'API :
/// - `--dart-define=API_URL=https://…` (builds de production, CI) ;
/// - en développement : `flutter run --dart-define-from-file=config/.env` ;
/// - à défaut, l'API locale sur le port 3000 (port par défaut du backend).
/// Sur l'émulateur Android, `localhost` désigne l'émulateur lui-même : il est
/// remplacé par 10.0.2.2, l'adresse de la machine hôte.
class Env {
  Env._();

  static const urlParDefaut = 'http://localhost:3000/api/v1';

  static String get baseUrl {
    const definie = String.fromEnvironment('API_URL');
    var url = definie.isNotEmpty ? definie : urlParDefaut;
    // Garde-fou d'exécution : les builds de publication sont déjà refusés sans
    // URL https (android/app/build.gradle.kts, phase de build iOS).
    if (kReleaseMode && !url.startsWith('https://')) {
      throw StateError(
        'API_URL doit être en https:// pour une version publiée (--dart-define=API_URL=https://…).',
      );
    }
    if (!kIsWeb && Platform.isAndroid) {
      url = url.replaceFirst(
        RegExp(r'//(localhost|127\.0\.0\.1)'),
        '//10.0.2.2',
      );
    }
    return url;
  }
}
