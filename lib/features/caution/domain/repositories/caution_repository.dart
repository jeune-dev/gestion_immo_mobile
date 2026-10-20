import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/caution.dart';

abstract class CautionRepository {
  Future<Either<Failure, PageResultat<Caution>>> getCautions(
      {required int page, String? statut});
  Future<Either<Failure, Caution>> getCaution(String id);
  Future<Either<Failure, void>> verser(String id, Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, void>> restituer(String id, Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, String>> ajouterJustificatif(String id, String chemin);
  Future<Either<Failure, void>> retenir(String id, Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, void>> repondreContestation(
      String id, String mouvementId, Map<String, dynamic> corps);
}
