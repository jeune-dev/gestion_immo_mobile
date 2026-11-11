import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/cache_images.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/features/auth/domain/entities/compte.dart';
import 'package:gestion_immo_mobile/features/auth/domain/entities/resultat_connexion.dart';
import 'package:gestion_immo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/activer_locataire.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/changer_mot_de_passe.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/connecter.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/deconnecter.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/get_compte.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/inscrire_proprietaire.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/restaurer_session.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/verifier_mfa.dart';
import 'package:gestion_immo_mobile/features/auth/data/models/compte_model.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/repositories/paiement_repository.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/encaisser_paiement.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/widgets/encaissement.dart';

// ── Connexion avec double authentification ───────────────────────────────────

final _compte = CompteModel.fromJson(const {
  'user': {
    'id': 'u1',
    'role': 'proprietaire',
    'first_name': 'Awa',
    'last_name': 'Diop',
  },
});

/// Le serveur exige un code de double authentification après le mot de passe.
class _DepotMfa implements AuthRepository {
  String? jetonRecu;
  String? codeRecu;
  Failure? refusMfa;

  @override
  Future<bool> sessionEnregistree() async => false;

  @override
  Future<Either<Failure, ResultatConnexion>> connecter({
    required String identifiant,
    required String motDePasse,
  }) async => const Right(DoubleAuthentificationRequise('jeton-mfa'));

  @override
  Future<Either<Failure, void>> verifierMfa({
    required String jeton,
    String? code,
    String? codeSecours,
  }) async {
    jetonRecu = jeton;
    codeRecu = code;
    final refus = refusMfa;
    return refus == null ? const Right(null) : Left(refus);
  }

  @override
  Future<Either<Failure, Compte>> lireCompte() async => Right(_compte);

  @override
  Future<void> deconnecter({bool sessionExpiree = false}) async {}

  @override
  dynamic noSuchMethod(Invocation appel) => super.noSuchMethod(appel);
}

AuthBloc _blocAuth(AuthRepository depot) => AuthBloc(
  restaurerSession: RestaurerSession(depot),
  connecter: Connecter(depot),
  verifierMfa: VerifierMfa(depot),
  inscrireProprietaire: InscrireProprietaire(depot),
  activerLocataire: ActiverLocataire(depot),
  changerMotDePasse: ChangerMotDePasse(depot),
  getCompte: GetCompte(depot),
  deconnecter: Deconnecter(depot),
);

// ── Renouvellement de session ────────────────────────────────────────────────

/// Serveur dont le jeton d'accès a expiré : plusieurs requêtes partent en même
/// temps et reçoivent toutes un 401 avant le renouvellement.
class _ServeurExpire implements HttpClientAdapter {
  int appelsRefresh = 0;
  final _refreshLibere = Completer<void>();

  ResponseBody _json(int status, Object corps) => ResponseBody.fromString(
    jsonEncode(corps),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  void libererRefresh() => _refreshLibere.complete();

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    if (o.path.endsWith('/auth/refresh')) {
      appelsRefresh++;
      await _refreshLibere.future;
      return _json(200, {
        'success': true,
        'data': {'access_token': 'neuf', 'refresh_token': 'refresh-2'},
      });
    }
    if (o.headers['Authorization'] != 'Bearer neuf') {
      return _json(401, {
        'success': false,
        'message': 'Jeton expiré',
        'error': {'code': 'TOKEN_EXPIRE'},
      });
    }
    return _json(200, {'success': true, 'data': o.path});
  }

  @override
  void close({bool force = false}) {}
}

// ── Encaissement ─────────────────────────────────────────────────────────────

class _Paiements implements PaiementRepository {
  final corps = <Map<String, dynamic>>[];
  final cles = <String>[];

  @override
  Future<Either<Failure, int>> encaisser(
    Map<String, dynamic> corps, {
    required String cle,
  }) async {
    this.corps.add(Map.of(corps));
    cles.add(cle);
    return const Right(1);
  }

  @override
  dynamic noSuchMethod(Invocation appel) => super.noSuchMethod(appel);
}

class _Refs extends ChangeNotifier implements ReferentielsService {
  @override
  String libelle(String famille, String? code) => code ?? '—';

  @override
  List<OptionRef> options(String famille) => famille == 'mode_paiement'
      ? const [OptionRef('especes', 'Espèces')]
      : const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('connexion avec double authentification', () {
    test(
      'mot de passe accepté : le code est demandé, puis la session s’ouvre',
      () async {
        final depot = _DepotMfa();
        final bloc = _blocAuth(depot);
        bloc.add(
          ConnexionDemandee(
            identifiant: 'awa@exemple.sn',
            motDePasse: 'Secret1!',
          ),
        );
        final attente = await bloc.stream.firstWhere(
          (s) => !s.enCours && s.mfaJeton != null,
        );
        expect(attente.connecte, isFalse);
        expect(attente.mfaJeton, 'jeton-mfa');

        bloc.add(MfaSoumise(code: '123456'));
        final connecte = await bloc.stream.firstWhere((s) => s.connecte);
        expect(depot.jetonRecu, 'jeton-mfa');
        expect(depot.codeRecu, '123456');
        expect(connecte.compte?.utilisateur.prenom, 'Awa');
        await bloc.close();
      },
    );

    test(
      'jeton de double authentification expiré : retour au mot de passe',
      () async {
        final depot = _DepotMfa()
          ..refusMfa = const ServerFailure(
            errorMessage: 'Jeton expiré',
            code: 'JETON_MFA_INVALIDE',
            status: 401,
          );
        final bloc = _blocAuth(depot);
        bloc.add(ConnexionDemandee(identifiant: 'awa', motDePasse: 'Secret1!'));
        await bloc.stream.firstWhere((s) => s.mfaJeton != null);

        bloc.add(MfaSoumise(code: '000000'));
        final refuse = await bloc.stream.firstWhere(
          (AuthState s) => !s.enCours && s.failure != null,
        );
        expect(refuse.connecte, isFalse);
        expect(refuse.mfaJeton, isNull);
        expect(refuse.failure?.code, 'JETON_MFA_INVALIDE');
        await bloc.close();
      },
    );
  });

  test('jeton expiré sur trois requêtes simultanées : UN seul renouvellement, trois rejeux', () async {
    FlutterSecureStorage.setMockInitialValues({
      'gi.refresh_token': 'refresh-1',
    });
    final serveur = _ServeurExpire();
    final jetons = TokenService()..accessToken = 'expire';
    final api = ApiClient(
      session: jetons,
      dio: Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))
        ..httpClientAdapter = serveur,
    );

    final reponses = Future.wait([
      api.get<String>('/a'),
      api.get<String>('/b'),
      api.get<String>('/c'),
    ]);
    await pumpEventQueue();
    serveur.libererRefresh();

    expect(await reponses, ['/a', '/b', '/c']);
    // Réutiliser un refresh token déjà consommé révoquerait toute la session.
    expect(serveur.appelsRefresh, 1);
    expect(await jetons.lireRefresh(), 'refresh-2');
  });

  group('appelApi', () {
    test('valeur rendue telle quelle', () async {
      expect(await appelApi(() async => 42), const Right<Failure, int>(42));
    });

    test('erreur de l’API : échec qui garde le code et le statut', () async {
      final r = await appelApi<int>(
        () async => throw const ApiException(
          'Conflit',
          code: 'DEJA_ANNULE',
          status: 409,
        ),
      );
      final f = r.fold((f) => f, (_) => null)!;
      expect(f.code, 'DEJA_ANNULE');
      expect(f.status, 409);
      expect(f.errorMessage, 'Conflit');
    });

    test('réponse illisible : « Réponse inattendue du serveur »', () async {
      final r = await appelApi<int>(() async => throw const FormatException());
      final f = r.fold((f) => f, (_) => null)!;
      expect(f, isA<ServerFailure>());
      expect(f.errorMessage, startsWith('Réponse inattendue du serveur'));
    });
  });

  group('cache des images', () {
    Uint8List octets(int n) => Uint8List(n);

    test('les plus anciennes sortent au-delà de la capacité', () {
      final cache = CacheImages(TokenService(), capaciteOctets: 10);
      cache.ecrire('a', octets(4));
      cache.ecrire('b', octets(4));
      expect(cache.lire('a'), isNotNull); // « a » redevient la plus récente
      cache.ecrire('c', octets(4));
      expect(cache.lire('b'), isNull);
      expect(cache.lire('a'), isNotNull);
      expect(cache.lire('c'), isNotNull);
      expect(cache.taille, 8);
    });

    test('une image plus grande que la capacité n’est pas gardée', () {
      final cache = CacheImages(TokenService(), capaciteOctets: 10);
      cache.ecrire('grande', octets(11));
      expect(cache.lire('grande'), isNull);
      expect(cache.taille, 0);
    });

    test('tout est oublié à la fermeture de la session', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final session = TokenService();
      final cache = CacheImages(session)..ecrire('a', octets(4));
      await session.effacer();
      expect(cache.lire('a'), isNull);
      expect(cache.taille, 0);
    });
  });

  test('liens externes : seuls les schémas attendus sont ouverts', () {
    for (final ok in [
      'https://pay.wave.com/c/123',
      'tel:+221770000000',
      'otpauth://totp/Kerimmo:awa?secret=ABC',
    ]) {
      expect(lienAutorise(Uri.parse(ok)), isTrue, reason: ok);
    }
    for (final refuse in [
      'file:///data/user/0/app/secret',
      'intent://scan/#Intent;scheme=zxing;end',
      'javascript:alert(1)',
      'sms:+221770000000',
    ]) {
      expect(lienAutorise(Uri.parse(refuse)), isFalse, reason: refuse);
    }
    expect(lienAutorise(null), isFalse);
    // Pages de paiement d'un backend local : admises hors version publiée.
    expect(lienAutorise(Uri.parse('http://localhost:3000/pay')), isTrue);
  });

  group('encaissement d’une échéance', () {
    late _Paiements paiements;
    setUp(() {
      paiements = _Paiements();
      GetIt.instance
        ..registerSingleton<ReferentielsService>(_Refs())
        ..registerSingleton(EncaisserPaiement(paiements));
    });
    tearDown(GetIt.instance.reset);

    testWidgets(
      'pré-rempli avec le reste dû, envoyé au bail de l’échéance avec une clé d’idempotence',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        const echeance = Echeance(
          id: 'ech1',
          bailId: 'bail1',
          libelle: 'Loyer septembre 2026',
          montantDu: 350000,
          montantPaye: 100000,
          statut: 'partiellement_paye',
        );
        bool? resultat;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.clair,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async =>
                        resultat = await encaisser(context, echeance: echeance),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Encaisser'));
        await tester.pumpAndSettle();

        expect(resultat, isTrue);
        expect(paiements.corps, hasLength(1));
        final corps = paiements.corps.single;
        expect(corps['lease_id'], 'bail1');
        expect(corps['rent_schedule_id'], 'ech1');
        expect(corps['amount'], 250000);
        expect(corps['method'], 'especes');
        expect(corps['paid_on'], isNotNull);
        expect(paiements.cles.single, isNotEmpty);
      },
    );
  });
}
