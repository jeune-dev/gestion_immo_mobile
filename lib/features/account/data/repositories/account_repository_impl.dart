import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';
import '../../domain/entities/session_appareil.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final TokenService jetons;
  AccountRepositoryImpl({required this.remoteDataSource, required this.jetons});

  @override
  Future<Either<Failure, void>> modifierProfil(
      Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.modifierProfil(corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<SessionAppareil>>> sessions() async {
    try {
      final resultat = await remoteDataSource.sessions();
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> revoquerSession(String id) async {
    try {
      await remoteDataSource.revoquerSession(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> revoquerToutes() async {
    try {
      final resultat = await remoteDataSource.revoquerToutes();
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, SecretMfa>> initialiserMfa(String motDePasse) async {
    try {
      final secretMfa = await remoteDataSource.initialiserMfa(motDePasse);
      return Right(secretMfa);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  /// L'activation ouvre une nouvelle session : les jetons sont remplacés.
  @override
  Future<Either<Failure, List<String>>> activerMfa(String code) async {
    try {
      final r = await remoteDataSource.activerMfa(code);
      await jetons.enregistrer(
          access: r['access_token'] as String,
          refresh: r['refresh_token'] as String?);
      return Right(((r['codes_secours'] as List?) ?? const []).cast<String>());
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> desactiverMfa(
      {required String motDePasse, required String code}) async {
    try {
      await remoteDataSource.desactiverMfa(motDePasse: motDePasse, code: code);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> regenererCodesSecours(
      {required String motDePasse, required String code}) async {
    try {
      final strings = await remoteDataSource.regenererCodesSecours(
          motDePasse: motDePasse, code: code);
      return Right(strings);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
