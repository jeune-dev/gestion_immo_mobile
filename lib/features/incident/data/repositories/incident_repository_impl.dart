import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/incident.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/incident_remote_datasource.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final IncidentRemoteDataSource remoteDataSource;
  IncidentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Incident>>> getIncidents({
    required int page,
    String? statut,
  }) =>
      appelApi(() => remoteDataSource.getIncidents(page: page, statut: statut));

  @override
  Future<Either<Failure, Incident>> getIncident(String id) =>
      appelApi(() async {
        final (incident, pieces) = await (
          remoteDataSource.getIncident(id),
          remoteDataSource.pieces(id),
        ).wait;
        return copieAvecPieces(incident, pieces);
      });

  @override
  Future<Either<Failure, Incident>> creerIncident(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.creerIncident(corps, cle: cle));

  @override
  Future<Either<Failure, void>> traiter(
    String id,
    String action,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.traiter(id, action, corps));

  @override
  Future<Either<Failure, void>> planifierTravaux(
    String id,
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.planifierTravaux(id, corps, cle: cle));
}
