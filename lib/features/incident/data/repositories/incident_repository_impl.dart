import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/incident.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/incident_remote_datasource.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final IncidentRemoteDataSource remoteDataSource;
  IncidentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Incident>>> getIncidents(
      {required int page, String? statut}) async {
    try {
      final incidents =
          await remoteDataSource.getIncidents(page: page, statut: statut);
      return Right(incidents);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Incident>> getIncident(String id) async {
    try {
      final (incident, pieces) = await (
        remoteDataSource.getIncident(id),
        remoteDataSource.pieces(id)
      ).wait;
      return Right(copieAvecPieces(incident, pieces));
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Incident>> creerIncident(Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      final incident = await remoteDataSource.creerIncident(corps, cle: cle);
      return Right(incident);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> traiter(
      String id, String action, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.traiter(id, action, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> planifierTravaux(
      String id, Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.planifierTravaux(id, corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
