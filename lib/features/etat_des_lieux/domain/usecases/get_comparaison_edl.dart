import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/etat_des_lieux.dart';
import '../repositories/etat_des_lieux_repository.dart';

class GetComparaisonEdl {
  final EtatDesLieuxRepository repository;
  GetComparaisonEdl(this.repository);

  Future<Either<Failure, ComparaisonEdl>> call(String bailId) =>
      repository.comparaison(bailId);
}
