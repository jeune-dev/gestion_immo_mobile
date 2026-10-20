import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/artisan.dart';

abstract class ArtisanRepository {
  Future<Either<Failure, PageResultat<Artisan>>> getArtisans(
      {required int page, String? recherche, bool actifsSeulement = false});
  Future<Either<Failure, Artisan>> getArtisan(String id);
  Future<Either<Failure, Artisan>> creerArtisan(Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, Artisan>> modifierArtisan(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> definirActivite(String id,
      {required bool actif});
  Future<Either<Failure, void>> supprimerArtisan(String id);
}
