import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/depense_repository.dart';

class CreerDepenseTravaux {
  final DepenseRepository repository;
  CreerDepenseTravaux(this.repository);

  Future<Either<Failure, void>> call(
          String travauxId, Map<String, dynamic> corps) =>
      repository.creerPourTravaux(travauxId, corps);
}
