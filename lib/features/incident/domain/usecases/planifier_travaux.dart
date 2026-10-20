import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/incident_repository.dart';

class PlanifierTravaux {
  final IncidentRepository repository;
  PlanifierTravaux(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      repository.planifierTravaux(id, corps, cle: cle);
}
