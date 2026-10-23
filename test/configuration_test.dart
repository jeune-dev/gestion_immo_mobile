import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_immo_mobile/core/config/env.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';

void main() {
  test("l'URL de l'API vient de config/.env (ou de l'exemple versionné)", () {
    final local = File('config/.env');
    final fichier = local.existsSync() ? local : File('config/.env.example');
    dotenv.loadFromString(envString: fichier.readAsStringSync());
    expect(Env.baseUrl, dotenv.get('API_URL'));
    expect(Env.baseUrl, endsWith('/api/v1'));
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
