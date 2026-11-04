import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/file_attente_service.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';

/// Répond selon [statut] ; `null` simule l'absence de réseau.
class _Serveur extends Interceptor {
  int? statut;
  final recus = <String>[];

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    if (statut == null) {
      return h.reject(
        DioException(requestOptions: o, type: DioExceptionType.connectionError),
      );
    }
    recus.add(o.path);
    if (statut! >= 400) {
      return h.reject(
        DioException(
          requestOptions: o,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: o,
            statusCode: statut,
            data: {'success': false, 'message': 'Refus'},
          ),
        ),
      );
    }
    h.resolve(
      Response(
        requestOptions: o,
        statusCode: 200,
        data: {'success': true, 'data': {}},
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Serveur serveur;

  FileAttenteService nouvelleFile() {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.interceptors.add(serveur);
    return FileAttenteService(
      ApiClient(session: TokenService(), baseUrl: 'http://test', dio: dio),
    );
  }

  Future<void> differer(FileAttenteService file, String chemin) =>
      file.envoyerOuDifferer<dynamic>(
        libelle: 'Dépense',
        chemin: chemin,
        corps: {'amount': 1},
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    serveur = _Serveur();
  });

  test('fin de session : la file revient au même compte et part', () async {
    final file = nouvelleFile();
    await file.ouvrirSession('a');
    await differer(file, '/depenses');
    expect(file.operations, hasLength(1));

    await file.fermerSession();
    expect(file.operations, isEmpty);

    serveur.statut = 200;
    await file.ouvrirSession('a');
    await file.synchroniser();
    expect(serveur.recus, ['/depenses']);
    expect(file.operations, isEmpty);
  });

  test('un autre compte ne voit ni n\'envoie la file', () async {
    final file = nouvelleFile();
    await file.ouvrirSession('a');
    await differer(file, '/depenses');
    await file.fermerSession();

    serveur.statut = 200;
    await file.ouvrirSession('b');
    await file.synchroniser();
    expect(file.operations, isEmpty);
    expect(serveur.recus, isEmpty);
  });

  test('401 : l\'opération reste intacte, sans erreur métier', () async {
    final file = nouvelleFile();
    await file.ouvrirSession('a');
    await differer(file, '/depenses');

    serveur.statut = 401;
    await file.synchroniser();
    expect(file.operations.single.erreur, isNull);
    expect(file.echec, isTrue);
  });

  test('erreur métier : l\'opération est gardée avec son message', () async {
    final file = nouvelleFile();
    await file.ouvrirSession('a');
    await differer(file, '/depenses');

    serveur.statut = 422;
    await file.synchroniser();
    expect(file.operations.single.erreur, isNotNull);
  });

  test('sans session, l\'erreur réseau remonte au lieu de perdre', () async {
    await expectLater(differer(nouvelleFile(), '/depenses'), throwsException);
  });
}
