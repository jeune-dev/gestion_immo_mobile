import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/depense_repository.dart';

class DesactiverCategorieDepense {
  final DepenseRepository repository;
  DesactiverCategorieDepense(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.desactiverCategorie(id);
}
