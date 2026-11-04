import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';

import '../repositories/espace_locataire_repository.dart';

class GetMaCharge {
  final EspaceLocataireRepository repository;
  GetMaCharge(this.repository);

  Future<Either<Failure, ChargeRefacturee>> call(String id) =>
      repository.charge(id);
}
