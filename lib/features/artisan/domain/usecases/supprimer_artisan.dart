import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/artisan_repository.dart';

class SupprimerArtisan {
  final ArtisanRepository repository;
  SupprimerArtisan(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.supprimerArtisan(id);
}
