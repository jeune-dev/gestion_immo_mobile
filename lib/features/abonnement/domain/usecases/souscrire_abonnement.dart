import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/abonnement_repository.dart';

class SouscrireAbonnement {
  final AbonnementRepository repository;
  SouscrireAbonnement(this.repository);

  /// Renvoie l'URL de paiement PayDunya à ouvrir.
  Future<Either<Failure, String?>> call(
          {required String planCode,
          required int mois,
          String? portefeuille}) =>
      repository.souscrire(
          planCode: planCode, mois: mois, portefeuille: portefeuille);
}
