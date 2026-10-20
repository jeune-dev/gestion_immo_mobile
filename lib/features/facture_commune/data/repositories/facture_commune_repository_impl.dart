import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/facture_commune.dart';
import '../../domain/repositories/facture_commune_repository.dart';
import '../datasources/facture_commune_remote_datasource.dart';

class FactureCommuneRepositoryImpl implements FactureCommuneRepository {
  final FactureCommuneRemoteDataSource remoteDataSource;
  FactureCommuneRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<FactureCommune>>> getFacturesCommunes(
      {required int page, String? statut}) async {
    try {
      final factureCommunes = await remoteDataSource.getFacturesCommunes(
          page: page, statut: statut);
      return Right(factureCommunes);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, FacturesARepartir>> aRepartir() async {
    try {
      final resultat = await remoteDataSource.aRepartir();
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, FactureCommune>> getFactureCommune(String id) async {
    try {
      final factureCommune = await remoteDataSource.getFactureCommune(id);
      return Right(factureCommune);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, FactureCommune>> creerFactureCommune(
      Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      final factureCommune =
          await remoteDataSource.creerFactureCommune(corps, cle: cle);
      return Right(factureCommune);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, FactureCommune>> modifierFactureCommune(
      String id, Map<String, dynamic> corps) async {
    try {
      final factureCommune =
          await remoteDataSource.modifierFactureCommune(id, corps);
      return Right(factureCommune);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> joindreDocument(
      String id, String chemin) async {
    try {
      await remoteDataSource.joindreDocument(id, chemin);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, ApercuRepartition>> apercu(
      String id, Map<String, dynamic> corps) async {
    try {
      final apercuRepartition = await remoteDataSource.apercu(id, corps);
      return Right(apercuRepartition);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> repartir(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.repartir(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> annulerFactureCommune(
      String id, String motif) async {
    try {
      await remoteDataSource.annulerFactureCommune(id, motif);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<ChargeRefacturee>>> charges(
      {required int page, String? statut}) async {
    try {
      final chargeRefacturees =
          await remoteDataSource.charges(page: page, statut: statut);
      return Right(chargeRefacturees);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
