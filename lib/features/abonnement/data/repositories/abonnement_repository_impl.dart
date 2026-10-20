import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../../domain/entities/abonnement.dart';
import '../../domain/repositories/abonnement_repository.dart';
import '../datasources/abonnement_remote_datasource.dart';

class AbonnementRepositoryImpl implements AbonnementRepository {
  final AbonnementRemoteDataSource remoteDataSource;
  AbonnementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, FicheAbonnement>> getFicheAbonnement() async {
    try {
      final ficheAbonnement = await remoteDataSource.getFicheAbonnement();
      return Right(ficheAbonnement);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, String?>> souscrire(
      {required String planCode,
      required int mois,
      String? portefeuille}) async {
    try {
      final resultat = await remoteDataSource.souscrire(
          planCode: planCode, mois: mois, portefeuille: portefeuille);
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
