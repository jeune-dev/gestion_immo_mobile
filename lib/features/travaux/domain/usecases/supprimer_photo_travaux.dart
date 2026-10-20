import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/travaux_repository.dart';

class SupprimerPhotoTravaux {
  final TravauxRepository repository;
  SupprimerPhotoTravaux(this.repository);

  Future<Either<Failure, void>> call(String id, String photoId) =>
      repository.supprimerPhoto(id, photoId);
}
