import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/facture_commune_repository.dart';

class AnnulerFactureCommune {
  final FactureCommuneRepository repository;
  AnnulerFactureCommune(this.repository);

  Future<Either<Failure, void>> call(String id, String motif) =>
      repository.annulerFactureCommune(id, motif);
}
