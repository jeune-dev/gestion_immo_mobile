import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/caisse.dart';
import '../../domain/repositories/caisse_repository.dart';
import '../datasources/caisse_remote_datasource.dart';

class CaisseRepositoryImpl implements CaisseRepository {
  final CaisseRemoteDataSource remoteDataSource;
  CaisseRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<MouvementCaisse>>> mouvements({
    required int page,
    required String du,
    required String au,
  }) => appelApi(() => remoteDataSource.mouvements(page: page, du: du, au: au));

  @override
  Future<Either<Failure, SyntheseCaisse>> synthese({
    required String du,
    required String au,
  }) => appelApi(() => remoteDataSource.synthese(du: du, au: au));

  @override
  Future<Either<Failure, void>> ajouterAutreRevenu(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.ajouterAutreRevenu(corps, cle: cle));

  @override
  Future<Either<Failure, void>> annulerOperationCaisse(
    String id,
    String motif,
  ) => appelApi(() => remoteDataSource.annulerOperationCaisse(id, motif));
}
