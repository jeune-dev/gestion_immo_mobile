import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/caution.dart';
import '../../domain/repositories/caution_repository.dart';
import '../datasources/caution_remote_datasource.dart';

class CautionRepositoryImpl implements CautionRepository {
  final CautionRemoteDataSource remoteDataSource;
  CautionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Caution>>> getCautions(
      {required int page, String? statut}) async {
    try {
      final cautions =
          await remoteDataSource.getCautions(page: page, statut: statut);
      return Right(cautions);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Caution>> getCaution(String id) async {
    try {
      final caution = await remoteDataSource.getCaution(id);
      return Right(caution);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> verser(String id, Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.verser(id, corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> restituer(String id, Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.restituer(id, corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, String>> ajouterJustificatif(
      String id, String chemin) async {
    try {
      final resultat = await remoteDataSource.ajouterJustificatif(id, chemin);
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> retenir(String id, Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.retenir(id, corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> repondreContestation(
      String id, String mouvementId, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.repondreContestation(id, mouvementId, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
