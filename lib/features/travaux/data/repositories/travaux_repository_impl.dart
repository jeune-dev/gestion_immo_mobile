import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/travaux.dart';
import '../../domain/repositories/travaux_repository.dart';
import '../datasources/travaux_remote_datasource.dart';

class TravauxRepositoryImpl implements TravauxRepository {
  final TravauxRemoteDataSource remoteDataSource;
  TravauxRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Travaux>>> getListeTravaux({
    required int page,
    String? statut,
  }) => appelApi(
    () => remoteDataSource.getListeTravaux(page: page, statut: statut),
  );

  @override
  Future<Either<Failure, Travaux>> getTravaux(String id) =>
      appelApi(() => remoteDataSource.getTravaux(id));

  @override
  Future<Either<Failure, Travaux>> creerTravaux(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.creerTravaux(corps, cle: cle));

  @override
  Future<Either<Failure, Travaux>> modifierTravaux(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierTravaux(id, corps));

  @override
  Future<Either<Failure, void>> changerStatutTravaux(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.changerStatutTravaux(id, corps));

  @override
  Future<Either<Failure, void>> ajouterPhoto(
    String id, {
    required String phase,
    required String chemin,
  }) => appelApi(
    () => remoteDataSource.ajouterPhoto(id, phase: phase, chemin: chemin),
  );

  @override
  Future<Either<Failure, void>> supprimerPhoto(String id, String photoId) =>
      appelApi(() => remoteDataSource.supprimerPhoto(id, photoId));
}
