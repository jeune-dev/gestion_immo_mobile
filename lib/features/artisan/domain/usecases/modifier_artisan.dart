import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/artisan.dart';
import '../repositories/artisan_repository.dart';

class ModifierArtisan {
  final ArtisanRepository repository;
  ModifierArtisan(this.repository);

  Future<Either<Failure, Artisan>> call(
          String id, Map<String, dynamic> corps) =>
      repository.modifierArtisan(id, corps);
}
