import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/immeuble.dart';

abstract class ImmeubleRepository {
  Future<Either<Failure, PageResultat<Immeuble>>> getImmeubles(
      {required int page, String? recherche});
  Future<Either<Failure, Immeuble>> getImmeuble(String id);
  Future<Either<Failure, Immeuble>> creerImmeuble(Map<String, dynamic> corps);
  Future<Either<Failure, Immeuble>> modifierImmeuble(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> supprimerImmeuble(String id);
}
