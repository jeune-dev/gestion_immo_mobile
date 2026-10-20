import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/appartement.dart';
import '../../domain/repositories/appartement_repository.dart';
import '../datasources/appartement_remote_datasource.dart';

class AppartementRepositoryImpl implements AppartementRepository {
  final AppartementRemoteDataSource remoteDataSource;
  AppartementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Appartement>>> getAppartements({
    required int page,
    String? recherche,
    String? statut,
    String? immeubleId,
    int? limite,
  }) async {
    try {
      final appartements = await remoteDataSource.getAppartements(
          page: page,
          recherche: recherche,
          statut: statut,
          immeubleId: immeubleId,
          limite: limite);
      return Right(appartements);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, FicheAppartement>> getFicheAppartement(String id,
      {required int annee}) async {
    try {
      final r = await Future.wait([
        remoteDataSource.getAppartement(id),
        remoteDataSource.rentabilite(id,
            du: '$annee-01-01', au: '$annee-12-31'),
        remoteDataSource.historique(id)
      ]);
      return Right(FicheAppartement(
        appartement: r[0] as Appartement,
        rentabilite: r[1] as RentabiliteAppartement,
        historique: r[2] as List<EvenementAppartement>,
      ));
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Appartement>> creerAppartement(
      Map<String, dynamic> corps) async {
    try {
      final appartement = await remoteDataSource.creerAppartement(corps);
      return Right(appartement);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Appartement>> modifierAppartement(
      String id, Map<String, dynamic> corps) async {
    try {
      final appartement = await remoteDataSource.modifierAppartement(id, corps);
      return Right(appartement);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> changerStatutAppartement(
      String id, String statut) async {
    try {
      await remoteDataSource.changerStatutAppartement(id, statut);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerAppartement(String id) async {
    try {
      await remoteDataSource.supprimerAppartement(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
