import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../../domain/entities/parametres.dart';
import '../../domain/repositories/parametres_repository.dart';
import '../datasources/parametres_remote_datasource.dart';

class ParametresRepositoryImpl implements ParametresRepository {
  final ParametresRemoteDataSource remoteDataSource;
  ParametresRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ParametresProprietaire>> lire() async {
    try {
      final parametresProprietaire = await remoteDataSource.lire();
      return Right(parametresProprietaire);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> modifierReglages(
      Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.modifierReglages(corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> modifierEspace(
      Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.modifierEspace(corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
