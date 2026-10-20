import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/incident.dart';

abstract class IncidentRepository {
  Future<Either<Failure, PageResultat<Incident>>> getIncidents(
      {required int page, String? statut});

  /// L'incident et les pièces jointes du locataire.
  Future<Either<Failure, Incident>> getIncident(String id);
  Future<Either<Failure, Incident>> creerIncident(Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, void>> traiter(
      String id, String action, Map<String, dynamic> corps);
  Future<Either<Failure, void>> planifierTravaux(
      String id, Map<String, dynamic> corps,
      {required String cle});
}
