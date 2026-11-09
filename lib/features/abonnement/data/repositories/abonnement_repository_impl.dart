import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../../domain/entities/abonnement.dart';
import '../../domain/repositories/abonnement_repository.dart';
import '../datasources/abonnement_remote_datasource.dart';

class AbonnementRepositoryImpl implements AbonnementRepository {
  final AbonnementRemoteDataSource remoteDataSource;
  AbonnementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, FicheAbonnement>> getFicheAbonnement() =>
      appelApi(() => remoteDataSource.getFicheAbonnement());

  @override
  Future<Either<Failure, String?>> souscrire({
    required String planCode,
    required int mois,
    String? portefeuille,
  }) => appelApi(
    () => remoteDataSource.souscrire(
      planCode: planCode,
      mois: mois,
      portefeuille: portefeuille,
    ),
  );
}
