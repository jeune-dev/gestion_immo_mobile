import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/facture_commune.dart';
import '../repositories/facture_commune_repository.dart';

class PrevisualiserRepartition {
  final FactureCommuneRepository repository;
  PrevisualiserRepartition(this.repository);

  Future<Either<Failure, ApercuRepartition>> call(
          String id, Map<String, dynamic> corps) =>
      repository.apercu(id, corps);
}
