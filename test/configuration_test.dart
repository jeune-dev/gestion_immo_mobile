import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_immo_mobile/core/config/env.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';

void main() {
  test("sans --dart-define, l'URL de l'API est celle du backend local", () {
    expect(Env.baseUrl, Env.urlParDefaut);
    expect(Env.baseUrl, endsWith('/api/v1'));
  });

  test(
    "l'exemple de configuration reste lisible par --dart-define-from-file",
    () {
      final lignes = File('config/.env.example')
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'));
      expect(lignes, everyElement(matches(r'^[A-Z_]+=\S+$')));
      expect(lignes.map((l) => l.split('=').first), contains('API_URL'));
    },
  );

  test('aucun fichier de configuration n’est embarqué dans l’application', () {
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('config/')));
  });

  // ── Chaîne des notifications push ────────────────────────────────────────
  //
  // Ces contrôles portent sur des FICHIERS, pas sur du code Dart, et c'est
  // voulu : la configuration des notifications tient dans quatre fichiers qui
  // doivent concorder, et chacun peut être réécrit par un outil — `flutter
  // create` régénère un manifeste, Xcode réécrit le `project.pbxproj` au
  // moindre clic. Une rupture ne se verrait alors que sur un vrai téléphone,
  // après publication, sans message d'erreur.

  test('le manifeste Android nomme le canal que MainActivity crée', () {
    final manifeste = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifeste,
      contains('default_notification_channel_id'),
      reason:
          'sans cette clé, FCM pose les notifications dans son canal « Divers »',
    );
    // Les deux côtés passent par la même ressource : c'est ce qui garantit
    // qu'ils ne divergent pas.
    expect(manifeste, contains('@string/canal_push'));
    expect(
      File(
        'android/app/src/main/kotlin/sn/gestionimmo/gestion_immo_mobile/MainActivity.kt',
      ).readAsStringSync(),
      contains('R.string.canal_push'),
      reason: 'le canal déclaré doit être créé, sinon il n’existe pas',
    );
    expect(
      File('android/app/src/main/res/values/strings.xml').readAsStringSync(),
      contains('name="canal_push"'),
    );
  });

  test('la petite icône de notification n’est pas le carré plein', () {
    final manifeste = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final icone = RegExp(
      r'default_notification_icon"\s*\n?\s*android:resource="([^"]+)"',
    ).firstMatch(manifeste)?.group(1);
    // Android ne garde que le canal alpha de cette image : `ic_launcher` est
    // un carré plein, il donnerait un carré blanc dans la barre d'état.
    expect(icone, isNotNull);
    expect(icone, isNot('@mipmap/ic_launcher'));
    expect(icone, '@drawable/ic_launcher_foreground');
  });

  test('iOS : l’entitlement et le mode d’arrière-plan des push sont là', () {
    expect(
      File('ios/Runner/Runner.entitlements').readAsStringSync(),
      contains('aps-environment'),
      reason: 'sans cette clé, APNs ne délivre rien, et rien ne le signale',
    );
    expect(
      File('ios/Runner/Info.plist').readAsStringSync(),
      contains('remote-notification'),
    );
    // L'entitlement n'existe que si le projet Xcode le désigne, sur les trois
    // configurations de la cible Runner (Debug, Release, Profile).
    final projet = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
          .allMatches(projet)
          .length,
      3,
    );
  });

  test('le Podfile et le projet Xcode visent la même version d’iOS', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    final duPodfile = RegExp(
      r"^platform :ios, '([\d.]+)'",
      multiLine: true,
    ).firstMatch(podfile)?.group(1);
    final duProjet = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);',
    ).firstMatch(File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync())
        ?.group(1);
    // Ligne commentée ou absente : CocoaPods retombe sur le minimum de Flutter
    // et les pods se construisent pour une version plus ancienne que l'app.
    expect(duPodfile, isNotNull);
    expect(duPodfile, duProjet);
  });

  test('montants FCFA de la charte', () {
    expect(montant(4250000), '4\u00a0250\u00a0000\u00a0FCFA');
    expect(lireMontant('350 000'), 350000);
  });

  test('une date calendaire ne change pas de jour selon le fuseau', () {
    expect(date('2026-09-05'), '05/09/2026');
    expect(date('2026-09-05T23:30:00Z'), '05/09/2026');
  });
}
