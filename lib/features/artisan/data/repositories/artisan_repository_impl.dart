import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/artisan.dart';
import '../../domain/repositories/artisan_repository.dart';
import '../datasources/artisan_remote_datasource.dart';

class ArtisanRepositoryImpl implements ArtisanRepository {
  final ArtisanRemoteDataSource remoteDataSource;
  ArtisanRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Artisan>>> getArtisans({
    required int page,
    String? recherche,
    bool actifsSeulement = false,
  }) => appelApi(
    () => remoteDataSource.getArtisans(
      page: page,
      recherche: recherche,
      actifsSeulement: actifsSeulement,
    ),
  );

  @override
  Future<Either<Failure, Artisan>> getArtisan(String id) =>
      appelApi(() => remoteDataSource.getArtisan(id));

  @override
  Future<Either<Failure, Artisan>> creerArtisan(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.creerArtisan(corps, cle: cle));

  @override
  Future<Either<Failure, Artisan>> modifierArtisan(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierArtisan(id, corps));

  @override
  Future<Either<Failure, void>> definirActivite(
    String id, {
    required bool actif,
  }) => appelApi(() => remoteDataSource.definirActivite(id, actif: actif));

  @override
  Future<Either<Failure, void>> supprimerArtisan(String id) =>
      appelApi(() => remoteDataSource.supprimerArtisan(id));
}
