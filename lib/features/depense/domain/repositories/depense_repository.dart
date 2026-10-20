import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/depense.dart';

abstract class DepenseRepository {
  Future<Either<Failure, PageResultat<Depense>>> getDepenses(
      {required int page, String? statut});

  /// `Right(null)` : pas de réseau, la dépense part dans la file hors ligne.
  Future<Either<Failure, Depense?>> creerDepense(Map<String, dynamic> corps);
  Future<Either<Failure, void>> creerPourTravaux(
      String travauxId, Map<String, dynamic> corps);
  Future<Either<Failure, Depense>> modifierDepense(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> annulerDepense(String id, String motif);
  Future<Either<Failure, void>> ajouterJustificatif(String id, String chemin);
  Future<Either<Failure, List<CategorieDepense>>> categories(
      {bool inclureInactives = false});
  Future<Either<Failure, void>> creerCategorie(Map<String, dynamic> corps);
  Future<Either<Failure, void>> modifierCategorie(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> desactiverCategorie(String id);
}
