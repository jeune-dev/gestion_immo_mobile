import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/caisse_repository.dart';

class AnnulerMouvementCaisse {
  final CaisseRepository repository;
  AnnulerMouvementCaisse(this.repository);

  Future<Either<Failure, void>> call(String id, String motif) =>
      repository.annulerOperationCaisse(id, motif);
}
