import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class RejeterRapprochement {
  final PaiementRepository repository;
  RejeterRapprochement(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps) =>
      repository.rejeterRapprochement(id, corps);
}
