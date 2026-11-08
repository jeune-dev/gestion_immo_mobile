import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../entities/facture_commune.dart';
import '../repositories/facture_commune_repository.dart';

/// Fiche d'une charge refacturée, côté propriétaire (§ 15).
class GetChargeRefacturee {
  final FactureCommuneRepository repository;
  GetChargeRefacturee(this.repository);

  Future<Either<Failure, ChargeRefacturee>> call(String id) =>
      repository.charge(id);
}
