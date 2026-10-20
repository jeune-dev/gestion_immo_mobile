import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

class GetIncidents {
  final IncidentRepository repository;
  GetIncidents(this.repository);

  Future<Either<Failure, PageResultat<Incident>>> call(
          {required int page, String? statut}) =>
      repository.getIncidents(page: page, statut: statut);
}
