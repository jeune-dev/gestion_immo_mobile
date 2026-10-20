import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/immeuble.dart';
import '../repositories/immeuble_repository.dart';

class GetImmeuble {
  final ImmeubleRepository repository;
  GetImmeuble(this.repository);

  Future<Either<Failure, Immeuble>> call(String id) =>
      repository.getImmeuble(id);
}
