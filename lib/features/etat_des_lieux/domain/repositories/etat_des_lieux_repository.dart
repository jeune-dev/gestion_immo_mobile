import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/etat_des_lieux.dart';

abstract class EtatDesLieuxRepository {
  Future<Either<Failure, PageResultat<EtatDesLieux>>> getEtatsDesLieux(
      {required int page});
  Future<Either<Failure, EtatDesLieux>> getEtatDesLieux(String id);
  Future<Either<Failure, EtatDesLieux>> creerEtatDesLieux(
      Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, void>> modifierEtatDesLieux(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> supprimerEtatDesLieux(String id);
  Future<Either<Failure, void>> enregistrerSaisie(
      String id, List<Map<String, dynamic>> elements);
  Future<Either<Failure, void>> ajouterPiece(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, void>> modifierPiece(
      String id, String pieceId, Map<String, dynamic> corps);
  Future<Either<Failure, void>> supprimerPiece(String id, String pieceId);
  Future<Either<Failure, void>> ajouterElement(
      String id, String pieceId, Map<String, dynamic> corps);
  Future<Either<Failure, void>> modifierElement(
      String id, String elementId, Map<String, dynamic> corps);
  Future<Either<Failure, void>> supprimerElement(String id, String elementId);
  Future<Either<Failure, void>> ajouterPhoto(
      String id, String elementId, String chemin);
  Future<Either<Failure, void>> supprimerPhoto(String id, String photoId);
  Future<Either<Failure, void>> soumettre(String id);
  Future<Either<Failure, EtatDesLieux>> corriger(String id);
  Future<Either<Failure, Uint8List>> pdf(String id);
  Future<Either<Failure, ComparaisonEdl>> comparaison(String bailId);
}
