import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class RejeterTransaction {
  final PaiementRepository repository;
  RejeterTransaction(this.repository);

  Future<Either<Failure, void>> call(String id, String motif) =>
      repository.rejeterTransaction(id, motif);
}
