import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class ValiderTransaction {
  final PaiementRepository repository;
  ValiderTransaction(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.validerTransaction(id);
}
