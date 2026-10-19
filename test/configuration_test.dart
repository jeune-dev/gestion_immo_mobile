import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_immo_mobile/core/api/api_client.dart';
import 'package:gestion_immo_mobile/core/format.dart';

void main() {
  test("l'URL de l'API vient du .env", () {
    dotenv.loadFromString(envString: File('.env').readAsStringSync());
    expect(urlApiParDefaut(), dotenv.get('API_URL'));
    expect(urlApiParDefaut(), endsWith('/api/v1'));
  });

  test('montants FCFA de la charte', () {
    expect(montant(4250000), '4 250 000 FCFA');
    expect(lireMontant('350 000'), 350000);
  });
}
