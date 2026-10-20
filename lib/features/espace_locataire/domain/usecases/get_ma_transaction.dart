import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMaTransaction {
  final EspaceLocataireRepository repository;
  GetMaTransaction(this.repository);

  Future<Either<Failure, TransactionPaiement>> call(String id) =>
      repository.transaction(id);
}
