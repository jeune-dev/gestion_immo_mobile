import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMesIncidents {
  final EspaceLocataireRepository repository;
  GetMesIncidents(this.repository);

  Future<Either<Failure, PageResultat<Incident>>> call({required int page}) =>
      repository.incidents(page: page);
}
