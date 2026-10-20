import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/travaux.dart';
import '../repositories/travaux_repository.dart';

class ModifierTravaux {
  final TravauxRepository repository;
  ModifierTravaux(this.repository);

  Future<Either<Failure, Travaux>> call(
          String id, Map<String, dynamic> corps) =>
      repository.modifierTravaux(id, corps);
}
