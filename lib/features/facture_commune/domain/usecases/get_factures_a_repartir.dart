import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/facture_commune.dart';
import '../repositories/facture_commune_repository.dart';

class GetFacturesARepartir {
  final FactureCommuneRepository repository;
  GetFacturesARepartir(this.repository);

  Future<Either<Failure, FacturesARepartir>> call() => repository.aRepartir();
}
