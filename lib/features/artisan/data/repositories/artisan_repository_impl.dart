import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/artisan.dart';
import '../../domain/repositories/artisan_repository.dart';
import '../datasources/artisan_remote_datasource.dart';

class ArtisanRepositoryImpl implements ArtisanRepository {
  final ArtisanRemoteDataSource remoteDataSource;
  ArtisanRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Artisan>>> getArtisans(
      {required int page,
      String? recherche,
      bool actifsSeulement = false}) async {
    try {
      final artisans = await remoteDataSource.getArtisans(
          page: page, recherche: recherche, actifsSeulement: actifsSeulement);
      return Right(artisans);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Artisan>> getArtisan(String id) async {
    try {
      final artisan = await remoteDataSource.getArtisan(id);
      return Right(artisan);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Artisan>> creerArtisan(Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      final artisan = await remoteDataSource.creerArtisan(corps, cle: cle);
      return Right(artisan);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Artisan>> modifierArtisan(
      String id, Map<String, dynamic> corps) async {
    try {
      final artisan = await remoteDataSource.modifierArtisan(id, corps);
      return Right(artisan);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> definirActivite(String id,
      {required bool actif}) async {
    try {
      await remoteDataSource.definirActivite(id, actif: actif);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerArtisan(String id) async {
    try {
      await remoteDataSource.supprimerArtisan(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
