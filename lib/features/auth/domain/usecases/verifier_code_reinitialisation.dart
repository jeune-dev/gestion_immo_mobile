import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../repositories/auth_repository.dart';

class VerifierCodeReinitialisation {
  final AuthRepository repository;
  VerifierCodeReinitialisation(this.repository);

  Future<Either<Failure, void>> call(String identifiant, String code) =>
      repository.verifierCodeReinitialisation(identifiant, code);
}
