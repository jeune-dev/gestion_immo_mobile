import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/espace_locataire_repository.dart';

class AjouterPieceSignalement {
  final EspaceLocataireRepository repository;
  AjouterPieceSignalement(this.repository);

  Future<Either<Failure, void>> call(String id, String chemin) =>
      repository.ajouterPieceIncident(id, chemin);
}
