import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/parametres_repository.dart';

class ModifierReglages {
  final ParametresRepository repository;
  ModifierReglages(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps) =>
      repository.modifierReglages(corps);
}
