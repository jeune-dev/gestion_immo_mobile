import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/immeuble.dart';
import '../../domain/repositories/immeuble_repository.dart';
import '../datasources/immeuble_remote_datasource.dart';

class ImmeubleRepositoryImpl implements ImmeubleRepository {
  final ImmeubleRemoteDataSource remoteDataSource;
  ImmeubleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Immeuble>>> getImmeubles(
      {required int page, String? recherche}) async {
    try {
      final immeubles =
          await remoteDataSource.getImmeubles(page: page, recherche: recherche);
      return Right(immeubles);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Immeuble>> getImmeuble(String id) async {
    try {
      final immeuble = await remoteDataSource.getImmeuble(id);
      return Right(immeuble);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Immeuble>> creerImmeuble(
      Map<String, dynamic> corps) async {
    try {
      final immeuble = await remoteDataSource.creerImmeuble(corps);
      return Right(immeuble);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Immeuble>> modifierImmeuble(
      String id, Map<String, dynamic> corps) async {
    try {
      final immeuble = await remoteDataSource.modifierImmeuble(id, corps);
      return Right(immeuble);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerImmeuble(String id) async {
    try {
      await remoteDataSource.supprimerImmeuble(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
