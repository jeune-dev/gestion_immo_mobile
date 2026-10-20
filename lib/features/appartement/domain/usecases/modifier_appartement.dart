import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/appartement.dart';
import '../repositories/appartement_repository.dart';

class ModifierAppartement {
  final AppartementRepository repository;
  ModifierAppartement(this.repository);

  Future<Either<Failure, Appartement>> call(
          String id, Map<String, dynamic> corps) =>
      repository.modifierAppartement(id, corps);
}
