import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetTransaction {
  final PaiementRepository repository;
  GetTransaction(this.repository);

  Future<Either<Failure, TransactionPaiement>> call(String id) =>
      repository.transaction(id);
}
