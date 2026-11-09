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

  test('montants FCFA de la charte', () {
    expect(montant(4250000), '4\u00a0250\u00a0000\u00a0FCFA');
    expect(lireMontant('350 000'), 350000);
  });

  test('une date calendaire ne change pas de jour selon le fuseau', () {
    expect(date('2026-09-05'), '05/09/2026');
    expect(date('2026-09-05T23:30:00Z'), '05/09/2026');
  });
}
