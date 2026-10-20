import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/depense.dart';
import '../repositories/depense_repository.dart';

class CreerDepense {
  final DepenseRepository repository;
  CreerDepense(this.repository);

  /// `Right(null)` : enregistrée hors ligne, envoyée au retour du réseau (§ 34).
  Future<Either<Failure, Depense?>> call(Map<String, dynamic> corps) =>
      repository.creerDepense(corps);
}
