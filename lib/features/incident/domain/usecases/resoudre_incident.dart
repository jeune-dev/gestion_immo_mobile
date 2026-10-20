import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/incident_repository.dart';

class ResoudreIncident {
  final IncidentRepository repository;
  ResoudreIncident(this.repository);

  Future<Either<Failure, void>> call(String id, {String? note}) =>
      repository.traiter(id, 'resoudre', {if (note != null) 'note': note});
}
