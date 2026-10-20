import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/appartement_repository.dart';

class SupprimerAppartement {
  final AppartementRepository repository;
  SupprimerAppartement(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.supprimerAppartement(id);
}
