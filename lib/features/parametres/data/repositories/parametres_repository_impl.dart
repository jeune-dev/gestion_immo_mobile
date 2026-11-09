import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../../domain/entities/parametres.dart';
import '../../domain/repositories/parametres_repository.dart';
import '../datasources/parametres_remote_datasource.dart';

class ParametresRepositoryImpl implements ParametresRepository {
  final ParametresRemoteDataSource remoteDataSource;
  ParametresRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ParametresProprietaire>> lire() =>
      appelApi(() => remoteDataSource.lire());

  @override
  Future<Either<Failure, void>> modifierReglages(Map<String, dynamic> corps) =>
      appelApi(() => remoteDataSource.modifierReglages(corps));

  @override
  Future<Either<Failure, void>> modifierEspace(Map<String, dynamic> corps) =>
      appelApi(() => remoteDataSource.modifierEspace(corps));
}
