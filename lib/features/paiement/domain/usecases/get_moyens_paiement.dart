import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetMoyensPaiement {
  final PaiementRepository repository;
  GetMoyensPaiement(this.repository);

  Future<Either<Failure, List<MoyenPaiement>>> call() => repository.moyens();
}
