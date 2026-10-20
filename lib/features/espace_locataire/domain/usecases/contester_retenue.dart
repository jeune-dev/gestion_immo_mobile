import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/espace_locataire_repository.dart';

class ContesterRetenue {
  final EspaceLocataireRepository repository;
  ContesterRetenue(this.repository);

  Future<Either<Failure, void>> call(String mouvementId, String message) =>
      repository.contesterRetenue(mouvementId, message);
}
