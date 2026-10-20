import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/depense_repository.dart';

class AnnulerDepense {
  final DepenseRepository repository;
  AnnulerDepense(this.repository);

  Future<Either<Failure, void>> call(String id, String motif) =>
      repository.annulerDepense(id, motif);
}
