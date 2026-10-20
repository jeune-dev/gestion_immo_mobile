import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/caisse.dart';

abstract class CaisseRepository {
  Future<Either<Failure, PageResultat<MouvementCaisse>>> mouvements(
      {required int page, required String du, required String au});
  Future<Either<Failure, SyntheseCaisse>> synthese(
      {required String du, required String au});
  Future<Either<Failure, void>> ajouterAutreRevenu(Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, void>> annulerOperationCaisse(String id, String motif);
}
