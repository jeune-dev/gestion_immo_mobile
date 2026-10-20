import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/incident_repository.dart';

class RejeterIncident {
  final IncidentRepository repository;
  RejeterIncident(this.repository);

  Future<Either<Failure, void>> call(String id, String motif) =>
      repository.traiter(id, 'rejeter', {'reason': motif});
}
