import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/immeuble.dart';
import '../repositories/immeuble_repository.dart';

class ModifierImmeuble {
  final ImmeubleRepository repository;
  ModifierImmeuble(this.repository);

  Future<Either<Failure, Immeuble>> call(
          String id, Map<String, dynamic> corps) =>
      repository.modifierImmeuble(id, corps);
}
