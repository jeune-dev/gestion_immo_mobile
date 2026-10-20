import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class DemanderReinitialisation {
  final AuthRepository repository;
  DemanderReinitialisation(this.repository);

  Future<Either<Failure, void>> call(String identifiant) =>
      repository.demanderReinitialisation(identifiant);
}
