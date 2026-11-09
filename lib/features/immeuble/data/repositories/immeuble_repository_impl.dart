import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/immeuble.dart';
import '../../domain/repositories/immeuble_repository.dart';
import '../datasources/immeuble_remote_datasource.dart';

class ImmeubleRepositoryImpl implements ImmeubleRepository {
  final ImmeubleRemoteDataSource remoteDataSource;
  ImmeubleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Immeuble>>> getImmeubles({
    required int page,
    String? recherche,
  }) => appelApi(
    () => remoteDataSource.getImmeubles(page: page, recherche: recherche),
  );

  @override
  Future<Either<Failure, Immeuble>> getImmeuble(String id) =>
      appelApi(() => remoteDataSource.getImmeuble(id));

  @override
  Future<Either<Failure, Immeuble>> creerImmeuble(Map<String, dynamic> corps) =>
      appelApi(() => remoteDataSource.creerImmeuble(corps));

  @override
  Future<Either<Failure, Immeuble>> modifierImmeuble(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierImmeuble(id, corps));

  @override
  Future<Either<Failure, void>> supprimerImmeuble(String id) =>
      appelApi(() => remoteDataSource.supprimerImmeuble(id));
}
