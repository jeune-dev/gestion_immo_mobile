import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class AjouterPhotoEdl {
  final EtatDesLieuxRepository repository;
  AjouterPhotoEdl(this.repository);

  Future<Either<Failure, void>> call(
          String id, String elementId, String chemin) =>
      repository.ajouterPhoto(id, elementId, chemin);
}
