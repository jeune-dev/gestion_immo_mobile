import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';

/// Serveur simulé : `/auth/refresh` répond selon [refresh], le reste exige un jeton.
class _Serveur implements HttpClientAdapter {
  /// 'ok', '401' ou 'reseau'.
  String refresh;
  int appelsRefresh = 0;
  _Serveur(this.refresh);

  ResponseBody _json(int status, Object corps) => ResponseBody.fromString(
    jsonEncode(corps),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    if (o.path.endsWith('/auth/refresh')) {
      appelsRefresh++;
      if (refresh == 'reseau') {
        throw DioException.connectionError(
          requestOptions: o,
          reason: 'hors ligne',
        );
      }
      if (refresh == '401') {
        return _json(401, {'success': false, 'message': 'Session expirée'});
      }
      return _json(200, {
        'success': true,
        'data': {'access_token': 'acces-neuf', 'refresh_token': 'refresh-neuf'},
      });
    }
    if (o.headers['Authorization'] != 'Bearer acces-neuf') {
      return _json(401, {'success': false, 'message': 'Jeton invalide'});
    }
    return _json(200, {
      'success': true,
      'data': {'ok': true},
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Serveur serveur;
  late TokenService jetons;
  late ApiClient api;
  late int expirations;

  void monter(String refresh) {
    FlutterSecureStorage.setMockInitialValues({
      'gi.refresh_token': 'refresh-ancien',
    });
    SharedPreferences.setMockInitialValues({});
    serveur = _Serveur(refresh);
    jetons = TokenService(); // démarrage : aucun jeton d'accès en mémoire
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))
      ..httpClientAdapter = serveur;
    expirations = 0;
    api = ApiClient(session: jetons, dio: dio)
      ..onSessionExpiree = () => expirations++;
  }

  test(
    'sans jeton d’accès (démarrage hors ligne), un 401 renouvelle la session',
    () async {
      monter('ok');
      final r = await api.get<Map<String, dynamic>>('/compte', cache: false);
      expect(r['ok'], isTrue);
      expect(serveur.appelsRefresh, 1);
      expect(jetons.accessToken, 'acces-neuf');
      expect(expirations, 0);
    },
  );

  test(
    'serveur injoignable au renouvellement : la session est gardée',
    () async {
      monter('reseau');
      await expectLater(
        api.get<dynamic>('/compte', cache: false),
        throwsA(
          isA<ApiException>().having((e) => e.estReseau, 'estReseau', isTrue),
        ),
      );
      expect(expirations, 0);
      expect(await jetons.lireRefresh(), 'refresh-ancien');
    },
  );

  test('renouvellement refusé (401) : la session est fermée', () async {
    monter('401');
    await expectLater(
      api.get<dynamic>('/compte', cache: false),
      throwsA(isA<ApiException>()),
    );
    expect(expirations, 1);
    expect(await jetons.lireRefresh(), isNull);
  });
}
