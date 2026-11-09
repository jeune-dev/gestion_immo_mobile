import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/document_app.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsRemoteDataSource remoteDataSource;
  DocumentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<DocumentApp>>> getDocuments({
    required String type,
    required String id,
  }) => appelApi(() => remoteDataSource.getDocuments(type: type, id: id));

  @override
  Future<Either<Failure, void>> ajouterPhoto({
    required String type,
    required String id,
    required String chemin,
    bool visibleLocataire = false,
  }) => appelApi(
    () => remoteDataSource.ajouterPhoto(
      type: type,
      id: id,
      chemin: chemin,
      visibleLocataire: visibleLocataire,
    ),
  );

  @override
  Future<Either<Failure, Uint8List>> telecharger(String id, {String? taille}) =>
      appelApi(() => remoteDataSource.telecharger(id, taille: taille));

  @override
  Future<Either<Failure, LienDocument>> lien(String id) =>
      appelApi(() => remoteDataSource.lien(id));

  @override
  Future<Either<Failure, void>> changerVisibilite(
    String id, {
    required bool visible,
  }) =>
      appelApi(() => remoteDataSource.changerVisibilite(id, visible: visible));

  @override
  Future<Either<Failure, void>> supprimerDocument(String id) =>
      appelApi(() => remoteDataSource.supprimerDocument(id));
}
