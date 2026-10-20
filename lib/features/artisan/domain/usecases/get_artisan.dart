import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/artisan.dart';
import '../repositories/artisan_repository.dart';

class GetArtisan {
  final ArtisanRepository repository;
  GetArtisan(this.repository);

  Future<Either<Failure, Artisan>> call(String id) => repository.getArtisan(id);
}
