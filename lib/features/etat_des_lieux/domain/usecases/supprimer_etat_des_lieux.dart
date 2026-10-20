import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class SupprimerEtatDesLieux {
  final EtatDesLieuxRepository repository;
  SupprimerEtatDesLieux(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.supprimerEtatDesLieux(id);
}
