import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/travaux.dart';
import '../../domain/repositories/travaux_repository.dart';
import '../datasources/travaux_remote_datasource.dart';

class TravauxRepositoryImpl implements TravauxRepository {
  final TravauxRemoteDataSource remoteDataSource;
  TravauxRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Travaux>>> getListeTravaux(
      {required int page, String? statut}) async {
    try {
      final travauxs =
          await remoteDataSource.getListeTravaux(page: page, statut: statut);
      return Right(travauxs);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Travaux>> getTravaux(String id) async {
    try {
      final travaux = await remoteDataSource.getTravaux(id);
      return Right(travaux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Travaux>> creerTravaux(Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      final travaux = await remoteDataSource.creerTravaux(corps, cle: cle);
      return Right(travaux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Travaux>> modifierTravaux(
      String id, Map<String, dynamic> corps) async {
    try {
      final travaux = await remoteDataSource.modifierTravaux(id, corps);
      return Right(travaux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> changerStatutTravaux(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.changerStatutTravaux(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterPhoto(String id,
      {required String phase, required String chemin}) async {
    try {
      await remoteDataSource.ajouterPhoto(id, phase: phase, chemin: chemin);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerPhoto(
      String id, String photoId) async {
    try {
      await remoteDataSource.supprimerPhoto(id, photoId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
