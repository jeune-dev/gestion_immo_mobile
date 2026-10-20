import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/document_app.dart';

abstract class DocumentsRepository {
  Future<Either<Failure, PageResultat<DocumentApp>>> getDocuments(
      {required String type, required String id});
  Future<Either<Failure, void>> ajouterPhoto(
      {required String type, required String id, required String chemin});
  Future<Either<Failure, Uint8List>> telecharger(String id, {String? taille});
  Future<Either<Failure, LienDocument>> lien(String id);
  Future<Either<Failure, void>> changerVisibilite(String id,
      {required bool visible});
  Future<Either<Failure, void>> supprimerDocument(String id);
}
