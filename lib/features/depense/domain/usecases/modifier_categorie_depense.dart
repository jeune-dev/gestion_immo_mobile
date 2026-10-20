import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/depense_repository.dart';

class ModifierCategorieDepense {
  final DepenseRepository repository;
  ModifierCategorieDepense(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps) =>
      repository.modifierCategorie(id, corps);
}
