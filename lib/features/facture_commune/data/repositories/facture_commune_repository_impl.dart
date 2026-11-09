import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/facture_commune.dart';
import '../../domain/repositories/facture_commune_repository.dart';
import '../datasources/facture_commune_remote_datasource.dart';

class FactureCommuneRepositoryImpl implements FactureCommuneRepository {
  final FactureCommuneRemoteDataSource remoteDataSource;
  FactureCommuneRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<FactureCommune>>> getFacturesCommunes({
    required int page,
    String? statut,
  }) => appelApi(
    () => remoteDataSource.getFacturesCommunes(page: page, statut: statut),
  );

  @override
  Future<Either<Failure, FacturesARepartir>> aRepartir() =>
      appelApi(() => remoteDataSource.aRepartir());

  @override
  Future<Either<Failure, FactureCommune>> getFactureCommune(String id) =>
      appelApi(() => remoteDataSource.getFactureCommune(id));

  @override
  Future<Either<Failure, FactureCommune>> creerFactureCommune(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.creerFactureCommune(corps, cle: cle));

  @override
  Future<Either<Failure, FactureCommune>> modifierFactureCommune(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierFactureCommune(id, corps));

  @override
  Future<Either<Failure, void>> joindreDocument(String id, String chemin) =>
      appelApi(() => remoteDataSource.joindreDocument(id, chemin));

  @override
  Future<Either<Failure, ApercuRepartition>> apercu(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.apercu(id, corps));

  @override
  Future<Either<Failure, void>> repartir(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.repartir(id, corps));

  @override
  Future<Either<Failure, void>> annulerFactureCommune(
    String id,
    String motif,
  ) => appelApi(() => remoteDataSource.annulerFactureCommune(id, motif));

  @override
  Future<Either<Failure, PageResultat<ChargeRefacturee>>> charges({
    required int page,
    String? statut,
  }) => appelApi(() => remoteDataSource.charges(page: page, statut: statut));

  @override
  Future<Either<Failure, ChargeRefacturee>> charge(String id) =>
      appelApi(() => remoteDataSource.charge(id));
}
