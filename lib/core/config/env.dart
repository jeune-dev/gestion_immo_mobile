import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Résolution de la configuration (reprise de Sign, adaptée au `config/.env` de développement).
///
/// URL de l'API, par ordre de priorité :
/// 1. `--dart-define=API_URL=…` (builds de production, CI) ;
/// 2. `API_URL` du fichier `config/.env` (développement) ;
/// 3. l'API locale sur le port 3000 (port par défaut du backend).
/// Sur l'émulateur Android, `localhost` désigne l'émulateur lui-même : il est
/// remplacé par 10.0.2.2, l'adresse de la machine hôte.
class Env {
  Env._();

  static String get baseUrl {
    const definie = String.fromEnvironment('API_URL');
    var url = definie.isNotEmpty
        ? definie
        : (dotenv.maybeGet('API_URL') ?? 'http://localhost:3000/api/v1');
    if (!kIsWeb && Platform.isAndroid) {
      url =
          url.replaceFirst(RegExp(r'//(localhost|127\.0\.0\.1)'), '//10.0.2.2');
    }
    return url;
  }
}
