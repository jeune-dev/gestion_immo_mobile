import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/facture_commune.dart';
import '../repositories/facture_commune_repository.dart';

class CreerFactureCommune {
  final FactureCommuneRepository repository;
  CreerFactureCommune(this.repository);

  Future<Either<Failure, FactureCommune>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.creerFactureCommune(corps, cle: cle);
}
