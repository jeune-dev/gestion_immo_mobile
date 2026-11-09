import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/etat_des_lieux.dart';
import '../../domain/repositories/etat_des_lieux_repository.dart';
import '../datasources/etat_des_lieux_remote_datasource.dart';

class EtatDesLieuxRepositoryImpl implements EtatDesLieuxRepository {
  final EtatDesLieuxRemoteDataSource remoteDataSource;
  EtatDesLieuxRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<EtatDesLieux>>> getEtatsDesLieux({
    required int page,
  }) => appelApi(() => remoteDataSource.getEtatsDesLieux(page: page));

  @override
  Future<Either<Failure, EtatDesLieux>> getEtatDesLieux(String id) =>
      appelApi(() => remoteDataSource.getEtatDesLieux(id));

  @override
  Future<Either<Failure, EtatDesLieux>> creerEtatDesLieux(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.creerEtatDesLieux(corps, cle: cle));

  @override
  Future<Either<Failure, void>> modifierEtatDesLieux(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierEtatDesLieux(id, corps));

  @override
  Future<Either<Failure, void>> supprimerEtatDesLieux(String id) =>
      appelApi(() => remoteDataSource.supprimerEtatDesLieux(id));

  @override
  Future<Either<Failure, void>> enregistrerSaisie(
    String id,
    List<Map<String, dynamic>> elements,
  ) => appelApi(() => remoteDataSource.enregistrerSaisie(id, elements));

  @override
  Future<Either<Failure, void>> ajouterPiece(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.ajouterPiece(id, corps));

  @override
  Future<Either<Failure, void>> modifierPiece(
    String id,
    String pieceId,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierPiece(id, pieceId, corps));

  @override
  Future<Either<Failure, void>> supprimerPiece(String id, String pieceId) =>
      appelApi(() => remoteDataSource.supprimerPiece(id, pieceId));

  @override
  Future<Either<Failure, void>> ajouterElement(
    String id,
    String pieceId,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.ajouterElement(id, pieceId, corps));

  @override
  Future<Either<Failure, void>> modifierElement(
    String id,
    String elementId,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.modifierElement(id, elementId, corps));

  @override
  Future<Either<Failure, void>> supprimerElement(String id, String elementId) =>
      appelApi(() => remoteDataSource.supprimerElement(id, elementId));

  @override
  Future<Either<Failure, void>> ajouterPhoto(
    String id,
    String elementId,
    String chemin,
  ) => appelApi(() => remoteDataSource.ajouterPhoto(id, elementId, chemin));

  @override
  Future<Either<Failure, void>> supprimerPhoto(String id, String photoId) =>
      appelApi(() => remoteDataSource.supprimerPhoto(id, photoId));

  @override
  Future<Either<Failure, void>> soumettre(String id) =>
      appelApi(() => remoteDataSource.soumettre(id));

  @override
  Future<Either<Failure, void>> acceptationPapier(String id, String photo) =>
      appelApi(() => remoteDataSource.acceptationPapier(id, photo));

  @override
  Future<Either<Failure, EtatDesLieux>> corriger(String id) =>
      appelApi(() => remoteDataSource.corriger(id));

  @override
  Future<Either<Failure, Uint8List>> pdf(String id) =>
      appelApi(() => remoteDataSource.pdf(id));

  @override
  Future<Either<Failure, ComparaisonEdl>> comparaison(String bailId) =>
      appelApi(() => remoteDataSource.comparaison(bailId));
}
