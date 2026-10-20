import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/facture_commune.dart';
import '../repositories/facture_commune_repository.dart';

class ModifierFactureCommune {
  final FactureCommuneRepository repository;
  ModifierFactureCommune(this.repository);

  Future<Either<Failure, FactureCommune>> call(
          String id, Map<String, dynamic> corps) =>
      repository.modifierFactureCommune(id, corps);
}
