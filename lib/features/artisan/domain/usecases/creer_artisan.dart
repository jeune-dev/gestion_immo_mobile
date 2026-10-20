import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/artisan.dart';
import '../repositories/artisan_repository.dart';

class CreerArtisan {
  final ArtisanRepository repository;
  CreerArtisan(this.repository);

  Future<Either<Failure, Artisan>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.creerArtisan(corps, cle: cle);
}
