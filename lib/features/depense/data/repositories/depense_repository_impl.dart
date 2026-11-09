import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/depense.dart';
import '../../domain/repositories/depense_repository.dart';
import '../datasources/depense_remote_datasource.dart';

class DepenseRepositoryImpl implements DepenseRepository {
  final DepenseRemoteDataSource remoteDataSource;
  DepenseRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Depense>>> getDepenses({
    required int page,
    String? statut,
  }) =>
      appelApi(() => remoteDataSource.getDepenses(page: page, statut: statut));

  @override
  Future<Either<Failure, Depense>> creerDepense(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.creer(corps, cle: cle));

  @override
  Future<Either<Failure, void>> creerPourTravaux(
    String travauxId,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.creerPourTravaux(travauxId, corps));

  @override
  Future<Either<Failure, Depense>> modifierDepense(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierDepense(id, corps));

  @override
  Future<Either<Failure, void>> annulerDepense(String id, String motif) =>
      appelApi(() => remoteDataSource.annulerDepense(id, motif));

  @override
  Future<Either<Failure, void>> ajouterJustificatif(String id, String chemin) =>
      appelApi(() => remoteDataSource.ajouterJustificatif(id, chemin));

  @override
  Future<Either<Failure, List<CategorieDepense>>> categories({
    bool inclureInactives = false,
  }) => appelApi(
    () => remoteDataSource.categories(inclureInactives: inclureInactives),
  );

  @override
  Future<Either<Failure, void>> creerCategorie(Map<String, dynamic> corps) =>
      appelApi(() => remoteDataSource.creerCategorie(corps));

  @override
  Future<Either<Failure, void>> modifierCategorie(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierCategorie(id, corps));

  @override
  Future<Either<Failure, void>> desactiverCategorie(String id) =>
      appelApi(() => remoteDataSource.desactiverCategorie(id));
}
