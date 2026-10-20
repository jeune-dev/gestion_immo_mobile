import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/compte.dart';
import '../repositories/auth_repository.dart';

class GetCompte {
  final AuthRepository repository;
  GetCompte(this.repository);

  Future<Either<Failure, Compte>> call() => repository.lireCompte();
}
