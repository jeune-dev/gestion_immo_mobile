import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/facture_commune.dart';

abstract class FactureCommuneRepository {
  Future<Either<Failure, PageResultat<FactureCommune>>> getFacturesCommunes(
      {required int page, String? statut});
  Future<Either<Failure, FacturesARepartir>> aRepartir();
  Future<Either<Failure, FactureCommune>> getFactureCommune(String id);
  Future<Either<Failure, FactureCommune>> creerFactureCommune(
      Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, FactureCommune>> modifierFactureCommune(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> joindreDocument(String id, String chemin);
  Future<Either<Failure, ApercuRepartition>> apercu(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> repartir(String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> annulerFactureCommune(String id, String motif);
  Future<Either<Failure, PageResultat<ChargeRefacturee>>> charges(
      {required int page, String? statut});
}
