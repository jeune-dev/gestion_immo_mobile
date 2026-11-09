import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/appartement.dart';
import '../../domain/repositories/appartement_repository.dart';
import '../datasources/appartement_remote_datasource.dart';

class AppartementRepositoryImpl implements AppartementRepository {
  final AppartementRemoteDataSource remoteDataSource;
  AppartementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Appartement>>> getAppartements({
    required int page,
    String? recherche,
    String? statut,
    String? immeubleId,
    int? limite,
  }) => appelApi(
    () => remoteDataSource.getAppartements(
      page: page,
      recherche: recherche,
      statut: statut,
      immeubleId: immeubleId,
      limite: limite,
    ),
  );

  @override
  Future<Either<Failure, FicheAppartement>> getFicheAppartement(
    String id, {
    required int annee,
  }) => appelApi(() async {
    final r = await Future.wait([
      remoteDataSource.getAppartement(id),
      remoteDataSource.rentabilite(id, du: '$annee-01-01', au: '$annee-12-31'),
      remoteDataSource.historique(id),
    ]);
    return FicheAppartement(
      appartement: r[0] as Appartement,
      rentabilite: r[1] as RentabiliteAppartement,
      historique: r[2] as List<EvenementAppartement>,
    );
  });

  @override
  Future<Either<Failure, Appartement>> creerAppartement(
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.creerAppartement(corps));

  @override
  Future<Either<Failure, Appartement>> modifierAppartement(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierAppartement(id, corps));

  @override
  Future<Either<Failure, void>> changerStatutAppartement(
    String id,
    String statut,
  ) => appelApi(() => remoteDataSource.changerStatutAppartement(id, statut));

  @override
  Future<Either<Failure, void>> supprimerAppartement(String id) =>
      appelApi(() => remoteDataSource.supprimerAppartement(id));
}
