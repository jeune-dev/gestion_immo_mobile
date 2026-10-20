import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/travaux.dart';

abstract class TravauxRepository {
  Future<Either<Failure, PageResultat<Travaux>>> getListeTravaux(
      {required int page, String? statut});
  Future<Either<Failure, Travaux>> getTravaux(String id);
  Future<Either<Failure, Travaux>> creerTravaux(Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, Travaux>> modifierTravaux(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> changerStatutTravaux(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> ajouterPhoto(String id,
      {required String phase, required String chemin});
  Future<Either<Failure, void>> supprimerPhoto(String id, String photoId);
}
