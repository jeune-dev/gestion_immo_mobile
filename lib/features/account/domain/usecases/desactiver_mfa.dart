import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class DesactiverMfa {
  final AccountRepository repository;
  DesactiverMfa(this.repository);

  Future<Either<Failure, void>> call(
          {required String motDePasse, required String code}) =>
      repository.desactiverMfa(motDePasse: motDePasse, code: code);
}
