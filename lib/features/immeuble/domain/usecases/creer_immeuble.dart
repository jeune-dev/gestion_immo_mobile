import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/immeuble.dart';
import '../repositories/immeuble_repository.dart';

class CreerImmeuble {
  final ImmeubleRepository repository;
  CreerImmeuble(this.repository);

  Future<Either<Failure, Immeuble>> call(Map<String, dynamic> corps) =>
      repository.creerImmeuble(corps);
}
