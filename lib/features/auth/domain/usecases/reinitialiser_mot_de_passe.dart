import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ReinitialiserMotDePasse {
  final AuthRepository repository;
  ReinitialiserMotDePasse(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps) =>
      repository.reinitialiserMotDePasse(corps);
}
