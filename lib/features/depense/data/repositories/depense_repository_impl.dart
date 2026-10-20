import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/depense.dart';
import '../../domain/repositories/depense_repository.dart';
import '../datasources/depense_remote_datasource.dart';

class DepenseRepositoryImpl implements DepenseRepository {
  final DepenseRemoteDataSource remoteDataSource;
  DepenseRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Depense>>> getDepenses(
      {required int page, String? statut}) async {
    try {
      final depenses =
          await remoteDataSource.getDepenses(page: page, statut: statut);
      return Right(depenses);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Depense?>> creerDepense(
      Map<String, dynamic> corps) async {
    try {
      final depense = await remoteDataSource.creerOuDifferer(corps);
      return Right(depense);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> creerPourTravaux(
      String travauxId, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.creerPourTravaux(travauxId, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Depense>> modifierDepense(
      String id, Map<String, dynamic> corps) async {
    try {
      final depense = await remoteDataSource.modifierDepense(id, corps);
      return Right(depense);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> annulerDepense(String id, String motif) async {
    try {
      await remoteDataSource.annulerDepense(id, motif);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterJustificatif(
      String id, String chemin) async {
    try {
      await remoteDataSource.ajouterJustificatif(id, chemin);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<CategorieDepense>>> categories(
      {bool inclureInactives = false}) async {
    try {
      final categorieDepenses =
          await remoteDataSource.categories(inclureInactives: inclureInactives);
      return Right(categorieDepenses);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> creerCategorie(
      Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.creerCategorie(corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> modifierCategorie(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.modifierCategorie(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> desactiverCategorie(String id) async {
    try {
      await remoteDataSource.desactiverCategorie(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
