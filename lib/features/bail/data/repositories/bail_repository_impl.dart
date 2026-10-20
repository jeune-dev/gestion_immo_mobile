import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/bail.dart';
import '../../domain/repositories/bail_repository.dart';
import '../datasources/bail_remote_datasource.dart';

class BailRepositoryImpl implements BailRepository {
  final BailRemoteDataSource remoteDataSource;
  BailRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Bail>>> getBaux(
      {required int page, String? statut, String? recherche}) async {
    try {
      final bails = await remoteDataSource.getBaux(
          page: page, statut: statut, recherche: recherche);
      return Right(bails);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, FicheBail>> getFicheBail(String id) async {
    try {
      final r = await Future.wait(
          [remoteDataSource.getBail(id), remoteDataSource.contrats(id)]);
      return Right(
          FicheBail(bail: r[0] as Bail, contrats: r[1] as List<ContratBail>));
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Bail>> creerBail(Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      final bail = await remoteDataSource.creerBail(corps, cle: cle);
      return Right(bail);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Bail>> modifierBail(
      String id, Map<String, dynamic> corps) async {
    try {
      final bail = await remoteDataSource.modifierBail(id, corps);
      return Right(bail);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> activer(String id) async {
    try {
      final strings = await remoteDataSource.activer(id);
      return Right(strings);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> annulerBail(String id, String motif) async {
    try {
      await remoteDataSource.annulerBail(id, motif);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> terminer(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.terminer(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> cloturer(String id) async {
    try {
      await remoteDataSource.cloturer(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> reviserLoyer(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.reviserLoyer(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> genererContrat(
      String id, Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.genererContrat(id, corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
