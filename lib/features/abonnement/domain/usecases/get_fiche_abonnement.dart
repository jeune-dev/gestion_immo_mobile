import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/abonnement.dart';
import '../repositories/abonnement_repository.dart';

class GetFicheAbonnement {
  final AbonnementRepository repository;
  GetFicheAbonnement(this.repository);

  Future<Either<Failure, FicheAbonnement>> call() =>
      repository.getFicheAbonnement();
}
