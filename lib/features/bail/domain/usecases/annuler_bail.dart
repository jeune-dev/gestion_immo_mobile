import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/bail_repository.dart';

class AnnulerBail {
  final BailRepository repository;
  AnnulerBail(this.repository);

  Future<Either<Failure, void>> call(String id, String motif) =>
      repository.annulerBail(id, motif);
}
