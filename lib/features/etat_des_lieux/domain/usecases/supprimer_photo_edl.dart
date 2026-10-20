import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class SupprimerPhotoEdl {
  final EtatDesLieuxRepository repository;
  SupprimerPhotoEdl(this.repository);

  Future<Either<Failure, void>> call(String id, String photoId) =>
      repository.supprimerPhoto(id, photoId);
}
