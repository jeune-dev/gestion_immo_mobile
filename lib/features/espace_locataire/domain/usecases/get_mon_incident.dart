import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMonIncident {
  final EspaceLocataireRepository repository;
  GetMonIncident(this.repository);

  Future<Either<Failure, Incident>> call(String id) => repository.incident(id);
}
