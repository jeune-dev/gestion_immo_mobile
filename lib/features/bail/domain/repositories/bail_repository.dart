import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/bail.dart';

abstract class BailRepository {
  Future<Either<Failure, PageResultat<Bail>>> getBaux(
      {required int page, String? statut, String? recherche});
  Future<Either<Failure, FicheBail>> getFicheBail(String id);
  Future<Either<Failure, Bail>> creerBail(Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, Bail>> modifierBail(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, List<String>>> activer(String id);
  Future<Either<Failure, void>> annulerBail(String id, String motif);
  Future<Either<Failure, void>> terminer(String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> cloturer(String id);
  Future<Either<Failure, void>> reviserLoyer(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> genererContrat(
      String id, Map<String, dynamic> corps,
      {required String cle});
}
