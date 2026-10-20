import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/document_app.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsRemoteDataSource remoteDataSource;
  DocumentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<DocumentApp>>> getDocuments(
      {required String type, required String id}) async {
    try {
      final documentApps =
          await remoteDataSource.getDocuments(type: type, id: id);
      return Right(documentApps);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterPhoto(
      {required String type,
      required String id,
      required String chemin}) async {
    try {
      await remoteDataSource.ajouterPhoto(type: type, id: id, chemin: chemin);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> telecharger(String id,
      {String? taille}) async {
    try {
      final octets = await remoteDataSource.telecharger(id, taille: taille);
      return Right(octets);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, LienDocument>> lien(String id) async {
    try {
      final lienDocument = await remoteDataSource.lien(id);
      return Right(lienDocument);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> changerVisibilite(String id,
      {required bool visible}) async {
    try {
      await remoteDataSource.changerVisibilite(id, visible: visible);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerDocument(String id) async {
    try {
      await remoteDataSource.supprimerDocument(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
