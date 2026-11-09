import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/bail.dart';
import '../../domain/repositories/bail_repository.dart';
import '../datasources/bail_remote_datasource.dart';

class BailRepositoryImpl implements BailRepository {
  final BailRemoteDataSource remoteDataSource;
  BailRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Bail>>> getBaux({
    required int page,
    String? statut,
  }) => appelApi(() => remoteDataSource.getBaux(page: page, statut: statut));

  @override
  Future<Either<Failure, FicheBail>> getFicheBail(String id) => appelApi(
    () async {
      final r = await Future.wait([
        remoteDataSource.getBail(id),
        remoteDataSource.contrats(id),
      ]);
      return FicheBail(bail: r[0] as Bail, contrats: r[1] as List<ContratBail>);
    },
  );

  @override
  Future<Either<Failure, Bail>> creerBail(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.creerBail(corps, cle: cle));

  @override
  Future<Either<Failure, Bail>> modifierBail(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierBail(id, corps));

  @override
  Future<Either<Failure, List<String>>> activer(String id) =>
      appelApi(() => remoteDataSource.activer(id));

  @override
  Future<Either<Failure, void>> annulerBail(String id, String motif) =>
      appelApi(() => remoteDataSource.annulerBail(id, motif));

  @override
  Future<Either<Failure, void>> terminer(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.terminer(id, corps));

  @override
  Future<Either<Failure, void>> cloturer(String id) =>
      appelApi(() => remoteDataSource.cloturer(id));

  @override
  Future<Either<Failure, void>> reviserLoyer(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.reviserLoyer(id, corps));

  @override
  Future<Either<Failure, Map<String, dynamic>>> action(
    String id,
    String chemin, {
    Map<String, dynamic> corps = const {},
    String? fichier,
  }) => appelApi(
    () => remoteDataSource.action(id, chemin, corps: corps, fichier: fichier),
  );

  @override
  Future<Either<Failure, void>> genererContrat(
    String id,
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.genererContrat(id, corps, cle: cle));
}
