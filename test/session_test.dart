import 'dart:async';
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
      final r = await api.get<Map<String, dynamic>>('/compte');
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
        api.get<dynamic>('/compte'),
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
      api.get<dynamic>('/compte'),
      throwsA(isA<ApiException>()),
    );
    expect(expirations, 1);
    expect(await jetons.lireRefresh(), isNull);
  });

  group('sessions : cas limites', () {
    ({ApiClient api, TokenService jetons, List<String> appels}) client(
      FutureOr<ResponseBody> Function(RequestOptions) repondre,
    ) {
      final appels = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))
        ..httpClientAdapter = _Script(appels, repondre);
      final jetons = TokenService();
      return (
        api: ApiClient(session: jetons, dio: dio),
        jetons: jetons,
        appels: appels,
      );
    }

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({'gi.refresh_token': 'R1'});
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'renouvellement déjà en cours côté serveur : le jeton est gardé',
      () async {
        final c = client(
          (_) => _reponse(401, {
            'success': false,
            'message': 'Session déjà renouvelée, réessayez',
            'error': {'code': 'SESSION_DEJA_RENOUVELEE'},
          }),
        );
        expect(await c.api.renouveler(), isFalse);
        expect(await c.jetons.lireRefresh(), 'R1');
      },
    );

    test('401 métier : ni renouvellement ni second envoi', () async {
      final c = client(
        (_) => _reponse(401, {
          'success': false,
          'message': 'Mot de passe actuel incorrect',
          'error': {'code': 'MOT_DE_PASSE_INCORRECT'},
        }),
      );
      await expectLater(
        c.api.post<dynamic>('/compte/mot-de-passe'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Mot de passe actuel incorrect',
          ),
        ),
      );
      expect(c.appels, ['POST /compte/mot-de-passe']);
    });

    test('jeton expiré : renouvelé puis rejoué', () async {
      var premier = true;
      final c = client((o) {
        if (o.path.endsWith('/auth/refresh')) {
          return _reponse(200, {
            'success': true,
            'data': {'access_token': 'A2', 'refresh_token': 'R2'},
          });
        }
        if (premier) {
          premier = false;
          return _reponse(401, {
            'success': false,
            'message': 'Session expirée',
            'error': {'code': 'TOKEN_EXPIRE'},
          });
        }
        return _reponse(200, {'success': true, 'data': {}});
      });
      await c.api.post<dynamic>('/depenses');
      expect(c.appels, [
        'POST /depenses',
        'POST /auth/refresh',
        'POST /depenses',
      ]);
    });

    test(
      'déconnexion pendant un renouvellement : jeton révoqué, coffre vide',
      () async {
        final attente = Completer<void>();
        final c = client((o) async {
          if (o.path.endsWith('/auth/deconnexion')) {
            return _reponse(200, {'success': true, 'data': null});
          }
          await attente.future;
          return _reponse(200, {
            'success': true,
            'data': {'access_token': 'A2', 'refresh_token': 'R2'},
          });
        });
        final enCours = c.api.renouveler();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await c.jetons.effacer();
        attente.complete();
        expect(await enCours, isFalse);
        expect(
          await const FlutterSecureStorage().read(key: 'gi.refresh_token'),
          isNull,
        );
        expect(c.jetons.accessToken, isNull);
        expect(c.appels, contains('POST /auth/deconnexion'));
      },
    );

    test('compte désactivé : le motif du serveur ferme la session', () async {
      final c = client(
        (_) => _reponse(403, {
          'success': false,
          'message': 'Compte désactivé. Contactez le support.',
          'error': {'code': 'COMPTE_INACTIF'},
        }),
      );
      String? motif;
      c.api.onCompteInactif = (m) => motif = m;
      await expectLater(
        c.api.get<dynamic>('/immeubles'),
        throwsA(isA<ApiException>()),
      );
      expect(motif, 'Compte désactivé. Contactez le support.');
    });

    test(
      'rien n’est gardé sur le téléphone : sans réseau, la lecture échoue',
      () async {
        var coupe = false;
        final c = client((o) {
          if (coupe) {
            throw DioException.connectionError(
              requestOptions: o,
              reason: 'hors ligne',
            );
          }
          return _reponse(200, {
            'success': true,
            'data': {'a': 1},
          });
        });
        expect((await c.api.get<Map<String, dynamic>>('/baux'))['a'], 1);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final p = await SharedPreferences.getInstance();
        expect(p.getKeys(), isEmpty);
        coupe = true;
        await expectLater(
          c.api.get<Map<String, dynamic>>('/baux'),
          throwsA(
            isA<ApiException>().having((e) => e.estReseau, 'estReseau', isTrue),
          ),
        );
      },
    );
  });
}

ResponseBody _reponse(int status, Object corps) => ResponseBody.fromString(
  jsonEncode(corps),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _Script implements HttpClientAdapter {
  final List<String> appels;
  final FutureOr<ResponseBody> Function(RequestOptions) repondre;
  _Script(this.appels, this.repondre);

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    appels.add('${o.method} ${o.path}');
    return repondre(o);
  }

  @override
  void close({bool force = false}) {}
}
