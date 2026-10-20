import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/etat_des_lieux.dart';
import '../repositories/etat_des_lieux_repository.dart';

class CorrigerEtatDesLieux {
  final EtatDesLieuxRepository repository;
  CorrigerEtatDesLieux(this.repository);

  Future<Either<Failure, EtatDesLieux>> call(String id) =>
      repository.corriger(id);
}
