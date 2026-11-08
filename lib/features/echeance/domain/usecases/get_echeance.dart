import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../entities/echeance_detail.dart';
import '../repositories/echeance_repository.dart';

class GetEcheance {
  final EcheanceRepository repository;
  GetEcheance(this.repository);

  Future<Either<Failure, EcheanceDetail>> call(
    String id, {
    bool espaceLocataire = false,
  }) => repository.getEcheance(id, espaceLocataire: espaceLocataire);
}
