import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/quittance.dart';
import '../../domain/repositories/quittance_repository.dart';
import '../datasources/quittance_remote_datasource.dart';

class QuittanceRepositoryImpl implements QuittanceRepository {
  final QuittanceRemoteDataSource remoteDataSource;
  QuittanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Quittance>>> getQuittances(
      {required int page, required bool espaceLocataire}) async {
    try {
      final quittances = await remoteDataSource.getQuittances(
          page: page, espaceLocataire: espaceLocataire);
      return Right(quittances);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> pdf(String id,
      {required bool espaceLocataire}) async {
    try {
      final octets =
          await remoteDataSource.pdf(id, espaceLocataire: espaceLocataire);
      return Right(octets);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
