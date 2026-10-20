import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/caisse.dart';
import '../../domain/repositories/caisse_repository.dart';
import '../datasources/caisse_remote_datasource.dart';

class CaisseRepositoryImpl implements CaisseRepository {
  final CaisseRemoteDataSource remoteDataSource;
  CaisseRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<MouvementCaisse>>> mouvements(
      {required int page, required String du, required String au}) async {
    try {
      final mouvementCaisses =
          await remoteDataSource.mouvements(page: page, du: du, au: au);
      return Right(mouvementCaisses);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, SyntheseCaisse>> synthese(
      {required String du, required String au}) async {
    try {
      final syntheseCaisse = await remoteDataSource.synthese(du: du, au: au);
      return Right(syntheseCaisse);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterAutreRevenu(Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.ajouterAutreRevenu(corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> annulerOperationCaisse(
      String id, String motif) async {
    try {
      await remoteDataSource.annulerOperationCaisse(id, motif);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
