import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/depense.dart';
import '../repositories/depense_repository.dart';

class ModifierDepense {
  final DepenseRepository repository;
  ModifierDepense(this.repository);

  Future<Either<Failure, Depense>> call(
          String id, Map<String, dynamic> corps) =>
      repository.modifierDepense(id, corps);
}
