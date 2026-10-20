import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/caution_repository.dart';

class RepondreContestation {
  final CautionRepository repository;
  RepondreContestation(this.repository);

  Future<Either<Failure, void>> call(
          String id, String mouvementId, Map<String, dynamic> corps) =>
      repository.repondreContestation(id, mouvementId, corps);
}
