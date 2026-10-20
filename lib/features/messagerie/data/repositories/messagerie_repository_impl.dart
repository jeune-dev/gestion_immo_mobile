import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/messagerie.dart';
import '../../domain/repositories/messagerie_repository.dart';
import '../datasources/messagerie_remote_datasource.dart';

class MessagerieRepositoryImpl implements MessagerieRepository {
  final MessagerieRemoteDataSource remoteDataSource;
  MessagerieRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<FilDiscussion>>> fils(
      {required int page, required bool espaceLocataire}) async {
    try {
      final filDiscussions = await remoteDataSource.fils(
          page: page, espaceLocataire: espaceLocataire);
      return Right(filDiscussions);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, String?>> filAvecLocataire(String locataireId) async {
    try {
      final p = await remoteDataSource.fils(
          page: 1, espaceLocataire: false, limite: 100);
      for (final f in p.items) {
        if (f.locataire?.id == locataireId) return Right(f.id);
      }
      return Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> messages(String filId,
      {required bool espaceLocataire}) async {
    try {
      final messages = await remoteDataSource.messages(filId,
          espaceLocataire: espaceLocataire);
      return Right(messages);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> marquerLu(String filId,
      {required bool espaceLocataire}) async {
    try {
      await remoteDataSource.marquerLu(filId, espaceLocataire: espaceLocataire);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Message>> envoyerTexte(String texte,
      {String? filId, String? locataireId}) async {
    try {
      final message = await remoteDataSource.envoyerTexte(texte,
          filId: filId, locataireId: locataireId);
      return Right(message);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Message>> envoyerPhoto(String chemin,
      {String? filId, String? locataireId}) async {
    try {
      final message = await remoteDataSource.envoyerPhoto(chemin,
          filId: filId, locataireId: locataireId);
      return Right(message);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
