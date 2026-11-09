import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/caution.dart';
import '../../domain/repositories/caution_repository.dart';
import '../datasources/caution_remote_datasource.dart';

class CautionRepositoryImpl implements CautionRepository {
  final CautionRemoteDataSource remoteDataSource;
  CautionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Caution>>> getCautions({
    required int page,
    String? statut,
  }) =>
      appelApi(() => remoteDataSource.getCautions(page: page, statut: statut));

  @override
  Future<Either<Failure, Caution>> getCaution(String id) =>
      appelApi(() => remoteDataSource.getCaution(id));

  @override
  Future<Either<Failure, void>> verser(
    String id,
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.verser(id, corps, cle: cle));

  @override
  Future<Either<Failure, void>> restituer(
    String id,
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.restituer(id, corps, cle: cle));

  @override
  Future<Either<Failure, String>> ajouterJustificatif(
    String id,
    String chemin,
  ) => appelApi(() => remoteDataSource.ajouterJustificatif(id, chemin));

  @override
  Future<Either<Failure, void>> retenir(
    String id,
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.retenir(id, corps, cle: cle));

  @override
  Future<Either<Failure, void>> repondreContestation(
    String id,
    String mouvementId,
    Map<String, dynamic> corps,
  ) => appelApi(
    () => remoteDataSource.repondreContestation(id, mouvementId, corps),
  );
}
