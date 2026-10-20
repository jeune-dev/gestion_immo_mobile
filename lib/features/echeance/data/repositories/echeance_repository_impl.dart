import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/repositories/echeance_repository.dart';
import '../datasources/echeance_remote_datasource.dart';

class EcheanceRepositoryImpl implements EcheanceRepository {
  final EcheanceRemoteDataSource remoteDataSource;
  EcheanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Echeance>>> getEcheances({
    required int page,
    String? bailId,
    String? locataireId,
    bool impayes = false,
    String? statut,
  }) async {
    try {
      final echeances = await remoteDataSource.getEcheances(
          page: page,
          bailId: bailId,
          locataireId: locataireId,
          impayes: impayes,
          statut: statut);
      return Right(echeances);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> annulerEcheance(String id, String motif) async {
    try {
      await remoteDataSource.annulerEcheance(id, motif);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
