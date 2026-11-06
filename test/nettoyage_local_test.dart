import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/services/nettoyage_local.dart';
import 'package:gestion_immo_mobile/core/utils/fichier_temporaire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory racine;

  setUp(() {
    racine = Directory.systemTemp.createTempSync('nettoyage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => racine.path,
        );
    SharedPreferences.setMockInitialValues({
      'cache:/baux?': 'v1:ancien',
      'gi.file_attente.compte': 'v1:ancien',
      'gi.referentiels': '{}',
    });
    FlutterSecureStorage.setMockInitialValues({
      'gi.refresh_token': 'R1',
      'gi.cle_donnees_locales': 'cle',
    });
  });
  tearDown(() => racine.deleteSync(recursive: true));

  test('efface les anciennes données et garde la session', () async {
    final photo = File('${racine.path}/photo_profil_u1.jpg')
      ..writeAsStringSync('x');
    final video = File('${racine.path}/video_d1.mp4')..writeAsStringSync('x');
    final autre = File('${racine.path}/autre.txt')..writeAsStringSync('x');
    final temporaire = await ecrireFichierTemporaire('a.pdf', [1]);

    await nettoyerStockageLocal();

    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    const coffre = FlutterSecureStorage();
    expect(await coffre.read(key: 'gi.cle_donnees_locales'), isNull);
    expect(await coffre.read(key: 'gi.refresh_token'), 'R1');
    expect(photo.existsSync(), isFalse);
    expect(video.existsSync(), isFalse);
    expect(temporaire.existsSync(), isFalse);
    expect(autre.existsSync(), isTrue);
  });

  test(
    'un fichier temporaire garde son nom et disparaît après usage',
    () async {
      final f = await ecrireFichierTemporaire('rapport.csv', [1, 2]);
      expect(f.path, endsWith('/rapport.csv'));
      expect(f.readAsBytesSync(), [1, 2]);
      await supprimerFichierTemporaire(f);
      expect(f.existsSync(), isFalse);
    },
  );
}
