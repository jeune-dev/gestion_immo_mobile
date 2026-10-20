import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/parametres_repository.dart';

class ModifierEspaceBailleur {
  final ParametresRepository repository;
  ModifierEspaceBailleur(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps) =>
      repository.modifierEspace(corps);
}
