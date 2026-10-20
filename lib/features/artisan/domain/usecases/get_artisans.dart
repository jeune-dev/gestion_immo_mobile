import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/artisan.dart';
import '../repositories/artisan_repository.dart';

class GetArtisans {
  final ArtisanRepository repository;
  GetArtisans(this.repository);

  Future<Either<Failure, PageResultat<Artisan>>> call(
          {required int page,
          String? recherche,
          bool actifsSeulement = false}) =>
      repository.getArtisans(
          page: page, recherche: recherche, actifsSeulement: actifsSeulement);
}
