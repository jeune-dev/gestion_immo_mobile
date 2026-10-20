import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/artisan_repository.dart';

class DefinirActiviteArtisan {
  final ArtisanRepository repository;
  DefinirActiviteArtisan(this.repository);

  Future<Either<Failure, void>> call(String id, {required bool actif}) =>
      repository.definirActivite(id, actif: actif);
}
