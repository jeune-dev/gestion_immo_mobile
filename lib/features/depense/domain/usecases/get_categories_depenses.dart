import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/depense.dart';
import '../repositories/depense_repository.dart';

class GetCategoriesDepenses {
  final DepenseRepository repository;
  GetCategoriesDepenses(this.repository);

  Future<Either<Failure, List<CategorieDepense>>> call(
          {bool inclureInactives = false}) =>
      repository.categories(inclureInactives: inclureInactives);
}
