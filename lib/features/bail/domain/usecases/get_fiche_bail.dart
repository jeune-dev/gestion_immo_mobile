import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/bail.dart';
import '../repositories/bail_repository.dart';

class GetFicheBail {
  final BailRepository repository;
  GetFicheBail(this.repository);

  Future<Either<Failure, FicheBail>> call(String id) =>
      repository.getFicheBail(id);
}
