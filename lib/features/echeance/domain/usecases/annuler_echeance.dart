import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/echeance_repository.dart';

class AnnulerEcheance {
  final EcheanceRepository repository;
  AnnulerEcheance(this.repository);

  Future<Either<Failure, void>> call(String id, String motif) =>
      repository.annulerEcheance(id, motif);
}
