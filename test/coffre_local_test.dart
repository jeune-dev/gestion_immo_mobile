import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/coffre_local.dart';
import 'package:gestion_immo_mobile/core/services/file_attente_service.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('chiffre et déchiffre ; le texte n’apparaît pas en clair', () async {
    final coffre = CoffreLocal();
    final chiffre = await coffre.chiffrer('Aminata Diop 771234567');
    expect(chiffre, isNot(contains('Aminata')));
    expect(await coffre.dechiffrer(chiffre), 'Aminata Diop 771234567');
  });

  test('un ancien cache en clair ou altéré est ignoré', () async {
    final coffre = CoffreLocal();
    expect(await coffre.dechiffrer('{"nom":"x"}'), isNull);
    expect(await coffre.dechiffrer('v1:AAAA'), isNull);
  });

  test(
    'la file hors ligne reprend l’ancien format puis le réécrit chiffré',
    () async {
      SharedPreferences.setMockInitialValues({
        'gi.file_attente': jsonEncode([
          {
            'id': 'a',
            'libelle': 'Dépense',
            'chemin': '/depenses',
            'corps': {'amount': 1},
            'cree_le': '2026-11-04T10:00:00.000',
          },
        ]),
      });
      final file = FileAttenteService(
        ApiClient(session: TokenService(), baseUrl: 'http://test'),
      );
      await file.ouvrirSession('compte-a');
      expect(file.operations.single.id, 'a');
      final p = await SharedPreferences.getInstance();
      expect(p.getString('gi.file_attente'), isNull);
      expect(
        CoffreLocal.estChiffre(p.getString('gi.file_attente.compte-a')!),
        isTrue,
      );

      final relue = FileAttenteService(
        ApiClient(session: TokenService(), baseUrl: 'http://test'),
      );
      await relue.ouvrirSession('compte-a');
      expect(relue.operations.single.chemin, '/depenses');
    },
  );

  test('même demande : même clé ; autre demande : autre clé', () {
    final a = cleStable('/x', {'amount': 1});
    expect(cleStable('/x', {'amount': 1}), a);
    expect(cleStable('/x', {'amount': 2}), isNot(a));
  });
}
