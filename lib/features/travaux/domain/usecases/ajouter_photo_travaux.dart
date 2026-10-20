import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/travaux_repository.dart';

class AjouterPhotoTravaux {
  final TravauxRepository repository;
  AjouterPhotoTravaux(this.repository);

  Future<Either<Failure, void>> call(String id,
          {required String phase, required String chemin}) =>
      repository.ajouterPhoto(id, phase: phase, chemin: chemin);
}
