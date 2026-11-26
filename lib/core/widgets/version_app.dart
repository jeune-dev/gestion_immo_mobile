import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';

/// Lecture unique : `PackageInfo.fromPlatform` passe par le code natif, et les
/// deux espaces affichent la même ligne.
final Future<PackageInfo> _paquet = PackageInfo.fromPlatform();

/// Version et numéro de build RÉELLEMENT installés, en pied d'écran de profil.
///
/// Lus dans le paquet (`CFBundleShortVersionString` / `CFBundleVersion` sur
/// iOS, `versionName` / `versionCode` sur Android), pas écrits à la main. Une
/// constante Dart finit toujours par mentir : on cherche alors quelle version
/// tourne sur un téléphone, et c'est précisément ce que cette ligne existe
/// pour répondre.
///
/// Le numéro de build compte autant que la version : deux dépôts successifs
/// portent souvent le même « 1.0.0 », et c'est le build qui les distingue.
class VersionApp extends StatelessWidget {
  const VersionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _paquet,
      builder: (context, instantane) {
        final infos = instantane.data;
        // Avant la réponse du natif : rien, mais la place est réservée, sinon
        // le bas de l'écran sursaute à l'arrivée du texte.
        final texte = infos == null
            ? ''
            : 'TerangaLoc ${infos.version} (build ${infos.buildNumber})';
        return Padding(
          padding: const EdgeInsets.only(top: AppTheme.espaceLg),
          child: Text(
            texte,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.texteSecondaire,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}
