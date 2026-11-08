import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../entities/quittance.dart';
import '../repositories/quittance_repository.dart';

class GetQuittance {
  final QuittanceRepository repository;
  GetQuittance(this.repository);

  Future<Either<Failure, Quittance>> call(
    String id, {
    bool espaceLocataire = false,
  }) => repository.getQuittance(id, espaceLocataire: espaceLocataire);
}
