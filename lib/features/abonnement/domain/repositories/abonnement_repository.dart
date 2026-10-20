import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/abonnement.dart';

abstract class AbonnementRepository {
  Future<Either<Failure, FicheAbonnement>> getFicheAbonnement();
  Future<Either<Failure, String?>> souscrire(
      {required String planCode, required int mois, String? portefeuille});
}
