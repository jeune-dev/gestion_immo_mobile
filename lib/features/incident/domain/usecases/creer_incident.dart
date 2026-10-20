import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

class CreerIncident {
  final IncidentRepository repository;
  CreerIncident(this.repository);

  Future<Either<Failure, Incident>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.creerIncident(corps, cle: cle);
}
