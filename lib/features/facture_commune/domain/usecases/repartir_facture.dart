import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/facture_commune_repository.dart';

class RepartirFacture {
  final FactureCommuneRepository repository;
  RepartirFacture(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps) =>
      repository.repartir(id, corps);
}
