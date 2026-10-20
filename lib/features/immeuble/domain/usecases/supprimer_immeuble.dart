import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/immeuble_repository.dart';

class SupprimerImmeuble {
  final ImmeubleRepository repository;
  SupprimerImmeuble(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.supprimerImmeuble(id);
}
