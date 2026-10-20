import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/parametres.dart';
import '../repositories/parametres_repository.dart';

class GetParametres {
  final ParametresRepository repository;
  GetParametres(this.repository);

  Future<Either<Failure, ParametresProprietaire>> call() => repository.lire();
}
