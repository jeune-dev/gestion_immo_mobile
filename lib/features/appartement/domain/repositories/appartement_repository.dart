import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/appartement.dart';

abstract class AppartementRepository {
  Future<Either<Failure, PageResultat<Appartement>>> getAppartements(
      {required int page,
      String? recherche,
      String? statut,
      String? immeubleId,
      int? limite});

  /// Appartement, rentabilité de l'année civile et derniers événements.
  Future<Either<Failure, FicheAppartement>> getFicheAppartement(String id,
      {required int annee});
  Future<Either<Failure, Appartement>> creerAppartement(
      Map<String, dynamic> corps);
  Future<Either<Failure, Appartement>> modifierAppartement(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> changerStatutAppartement(
      String id, String statut);
  Future<Either<Failure, void>> supprimerAppartement(String id);
}
