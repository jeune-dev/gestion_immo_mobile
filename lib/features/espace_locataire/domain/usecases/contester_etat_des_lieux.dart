import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/espace_locataire_repository.dart';

class ContesterEtatDesLieux {
  final EspaceLocataireRepository repository;
  ContesterEtatDesLieux(this.repository);

  Future<Either<Failure, void>> call(String id, String commentaire) =>
      repository.contesterEtatDesLieux(id, commentaire);
}
