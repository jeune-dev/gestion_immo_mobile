import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../../domain/entities/tableau_de_bord.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, TableauDeBord>> tableauDeBord() =>
      appelApi(() => remoteDataSource.tableauDeBord());

  @override
  Future<Either<Failure, SerieFinanciere>> serieFinanciere(int nbMois) =>
      appelApi(() => remoteDataSource.serieFinanciere(nbMois));
}
