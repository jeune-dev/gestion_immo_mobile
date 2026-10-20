import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

class GetIncident {
  final IncidentRepository repository;
  GetIncident(this.repository);

  Future<Either<Failure, Incident>> call(String id) =>
      repository.getIncident(id);
}
