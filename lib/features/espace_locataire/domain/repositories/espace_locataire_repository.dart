import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import '../entities/espace_locataire.dart';

abstract class EspaceLocataireRepository {
  Future<Either<Failure, List<LogementLocataire>>> accueil();
  Future<Either<Failure, List<LogementLocataire>>> logements();
  Future<Either<Failure, PageResultat<Echeance>>> echeances(
      {required int page, required bool aPayer});
  Future<Either<Failure, PageResultat<Paiement>>> paiements(
      {required int page});
  Future<Either<Failure, PageResultat<TransactionPaiement>>> transactions(
      {required int page});
  Future<Either<Failure, TransactionPaiement>> transaction(String id);
  Future<Either<Failure, MoyensPaiementLocataire>> moyensPaiement(
      String bailId);
  Future<Either<Failure, DemandePaiement>> payer(
      {String? echeanceId,
      String? chargeId,
      required String portefeuille,
      int? montant});
  Future<Either<Failure, void>> declarerPreuve(Map<String, dynamic> champs,
      {String? capture});
  Future<Either<Failure, List<Caution>>> cautions();
  Future<Either<Failure, void>> contesterRetenue(
      String mouvementId, String message);
  Future<Either<Failure, PageResultat<ChargeRefacturee>>> charges(
      {required int page});
  Future<Either<Failure, void>> consentementWhatsapp({required bool accorde});
  Future<Either<Failure, PageResultat<Incident>>> incidents(
      {required int page});
  Future<Either<Failure, Incident>> incident(String id);
  Future<Either<Failure, Incident?>> signalerOuDifferer(
      Map<String, dynamic> corps);
  Future<Either<Failure, void>> ajouterPieceIncident(String id, String chemin);
  Future<Either<Failure, PageResultat<EtatDesLieux>>> etatsDesLieux(
      {required int page});
  Future<Either<Failure, EtatDesLieux>> etatDesLieux(String id);
  Future<Either<Failure, Uint8List>> pdfEtatDesLieux(String id);
  Future<Either<Failure, void>> accepterEtatDesLieux(String id);
  Future<Either<Failure, void>> contesterEtatDesLieux(
      String id, String commentaire);
}
