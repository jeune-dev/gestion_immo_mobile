import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/depense_repository.dart';

class AjouterJustificatifDepense {
  final DepenseRepository repository;
  AjouterJustificatifDepense(this.repository);

  Future<Either<Failure, void>> call(String id, String chemin) =>
      repository.ajouterJustificatif(id, chemin);
}
