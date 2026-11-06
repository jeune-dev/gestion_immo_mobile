import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';
import 'package:gestion_immo_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:gestion_immo_mobile/features/auth/data/repositories/auth_repository_impl.dart';
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
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_state.dart';

const _panne = ServerFailure(errorMessage: 'Panne', status: 500);

/// Session et réponses pilotées par chaque test.
class _Depot implements AuthRepository {
  bool session = true;
  bool perdreAuRenouvellement = false;
  bool perdreALaLecture = false;
  bool coffreIllisible = false;
  bool fermetureEnErreur = false;
  Either<Failure, Compte> compte = const Left(_panne);
  int fermetures = 0;

  @override
  Future<bool> sessionEnregistree() async {
    if (coffreIllisible) throw StateError('coffre illisible');
    return session;
  }

  @override
  Future<bool> restaurerSession() async {
    if (perdreAuRenouvellement) session = false;
    return !perdreAuRenouvellement;
  }

  @override
  Future<Either<Failure, Compte>> lireCompte() async {
    if (perdreALaLecture) session = false;
    return compte;
  }

  @override
  Future<Either<Failure, ResultatConnexion>> connecter({
    required String identifiant,
    required String motDePasse,
  }) async => const Right(SessionOuverte());

  @override
  Future<void> deconnecter({bool sessionExpiree = false}) async {
    fermetures++;
    session = false;
    if (fermetureEnErreur) throw StateError('fermeture');
  }

  @override
  dynamic noSuchMethod(Invocation appel) => super.noSuchMethod(appel);
}

class _Distant implements AuthRemoteDataSource {
  Object? erreur;
  final revoques = <String?>[];

  @override
  Future<void> deconnecter(String? refreshToken) async {
    final e = erreur;
    if (e != null) throw e;
    revoques.add(refreshToken);
  }

  @override
  Future<Map<String, dynamic>> connecter(Map<String, dynamic> corps) async => {
    'access_token': 'A',
    'refresh_token': 'R-nouveau',
  };

  @override
  dynamic noSuchMethod(Invocation appel) => super.noSuchMethod(appel);
}

void main() {
  group('session au démarrage et fermeture', () {
    late _Depot depot;
    late AuthBloc bloc;

    setUp(() {
      depot = _Depot();
      bloc = AuthBloc(
        restaurerSession: RestaurerSession(depot),
        connecter: Connecter(depot),
        verifierMfa: VerifierMfa(depot),
        inscrireProprietaire: InscrireProprietaire(depot),
        activerLocataire: ActiverLocataire(depot),
        changerMotDePasse: ChangerMotDePasse(depot),
        getCompte: GetCompte(depot),
        deconnecter: Deconnecter(depot),
      );
    });
    tearDown(() => bloc.close());

    Future<AuthState> attendre(bool Function(AuthState) condition) =>
        bloc.stream.firstWhere(condition);

    test(
      'compte illisible, jeton gardé : erreur à réessayer, session intacte',
      () async {
        bloc.add(AuthDemarree());
        final etat = await attendre((s) => s.failure != null);
        expect(etat.statut, StatutSession.inconnu);
        expect(depot.fermetures, 0);
      },
    );

    test('coffre illisible : pas de chargement sans fin', () async {
      depot.coffreIllisible = true;
      bloc.add(AuthDemarree());
      final etat = await attendre((s) => s.failure != null);
      expect(etat.statut, StatutSession.inconnu);
    });

    test(
      'session refusée au lancement : tout est fermé, avec une explication',
      () async {
        depot.perdreAuRenouvellement = true;
        bloc.add(AuthDemarree());
        final etat = await attendre(
          (s) => s.statut == StatutSession.deconnecte,
        );
        expect(etat.information, isNotNull);
        expect(depot.fermetures, 1);
      },
    );

    test('session perdue pendant la lecture du compte : fermée, avec une explication', () async {
      depot.perdreALaLecture = true;
      bloc.add(AuthDemarree());
      final etat = await attendre((s) => s.statut == StatutSession.deconnecte);
      expect(etat.information, isNotNull);
      expect(depot.fermetures, 1);
    });

    test(
      'compte illisible juste après la connexion : session refermée',
      () async {
        bloc.add(ConnexionDemandee(identifiant: 'a@b.sn', motDePasse: 'x'));
        final etat = await attendre((s) => s.failure != null);
        expect(depot.fermetures, 1);
        expect(etat.enCours, isFalse);
        expect(etat.connecte, isFalse);
      },
    );

    test('déconnexion en erreur : l’utilisateur sort quand même', () async {
      depot.fermetureEnErreur = true;
      bloc.add(DeconnexionDemandee());
      expect((await attendre((s) => s.deconnexion)).deconnexion, isTrue);
      final etat = await attendre((s) => s.statut == StatutSession.deconnecte);
      expect(etat.deconnexion, isFalse);
    });

    test(
      'une expiration pendant la déconnexion ne ferme pas deux fois',
      () async {
        bloc.add(DeconnexionDemandee());
        bloc.add(SessionExpiree());
        await attendre((s) => s.statut == StatutSession.deconnecte);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(depot.fermetures, 1);
      },
    );

    test('motif du serveur affiché à la fermeture', () async {
      bloc.add(SessionExpiree('Compte désactivé.'));
      final etat = await attendre((s) => s.statut == StatutSession.deconnecte);
      expect(etat.information, 'Compte désactivé.');
    });
  });

  testWidgets('écran de démarrage : réessayer rouvre la session', (t) async {
    final depot = _Depot();
    final bloc = AuthBloc(
      restaurerSession: RestaurerSession(depot),
      connecter: Connecter(depot),
      verifierMfa: VerifierMfa(depot),
      inscrireProprietaire: InscrireProprietaire(depot),
      activerLocataire: ActiverLocataire(depot),
      changerMotDePasse: ChangerMotDePasse(depot),
      getCompte: GetCompte(depot),
      deconnecter: Deconnecter(depot),
    );
    addTearDown(bloc.close);
    final routeur = AppRouter.creer(bloc);
    addTearDown(routeur.dispose);
    await t.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: routeur),
      ),
    );
    bloc.add(AuthDemarree());
    await t.pumpAndSettle();
    expect(find.text('Panne'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await t.tap(find.text('Réessayer'));
    await t.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    expect(depot.fermetures, 0);
    expect(await depot.sessionEnregistree(), isTrue);
  });

  group('dépôt : révocation et cache', () {
    late _Distant distant;
    late TokenService jetons;
    late AuthRepositoryImpl depot;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({'gi.refresh_token': 'R1'});
      distant = _Distant();
      jetons = TokenService();
      final api = ApiClient(
        session: jetons,
        dio: Dio(BaseOptions(baseUrl: 'http://api.test')),
      );
      depot = AuthRepositoryImpl(
        remoteDataSource: distant,
        api: api,
        jetons: jetons,
      );
    });

    test('déconnexion hors ligne : révocation reportée, puis envoyée à la connexion', () async {
      distant.erreur = const ApiException('Hors ligne', code: 'RESEAU');
      await depot.deconnecter();
      expect(await jetons.lireRefresh(), isNull);
      expect(await jetons.lireRevocation(), 'R1');

      distant.erreur = null;
      await depot.connecter(identifiant: 'a@b.sn', motDePasse: 'x');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(distant.revoques, ['R1']);
      expect(await jetons.lireRevocation(), isNull);
    });

    test('refus définitif du serveur : rien à reporter', () async {
      distant.erreur = const ApiException('Invalide', status: 422);
      await depot.deconnecter();
      expect(await jetons.lireRevocation(), isNull);
    });
  });
}
