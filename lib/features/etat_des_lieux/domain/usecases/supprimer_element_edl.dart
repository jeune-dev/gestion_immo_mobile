import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class SupprimerElementEdl {
  final EtatDesLieuxRepository repository;
  SupprimerElementEdl(this.repository);

  Future<Either<Failure, void>> call(String id, String elementId) =>
      repository.supprimerElement(id, elementId);
}
