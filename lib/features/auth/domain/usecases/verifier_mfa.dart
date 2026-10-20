import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class VerifierMfa {
  final AuthRepository repository;
  VerifierMfa(this.repository);

  Future<Either<Failure, void>> call(
          {required String jeton, String? code, String? codeSecours}) =>
      repository.verifierMfa(
          jeton: jeton, code: code, codeSecours: codeSecours);
}
