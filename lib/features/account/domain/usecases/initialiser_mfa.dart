import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/session_appareil.dart';
import '../repositories/account_repository.dart';

class InitialiserMfa {
  final AccountRepository repository;
  InitialiserMfa(this.repository);

  Future<Either<Failure, SecretMfa>> call(String motDePasse) =>
      repository.initialiserMfa(motDePasse);
}
