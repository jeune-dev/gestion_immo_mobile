import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/depense_repository.dart';

class CreerCategorieDepense {
  final DepenseRepository repository;
  CreerCategorieDepense(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps) =>
      repository.creerCategorie(corps);
}
