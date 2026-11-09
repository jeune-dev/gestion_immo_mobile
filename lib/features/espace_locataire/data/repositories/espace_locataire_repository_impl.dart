import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../domain/entities/accords.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';

import '../../domain/entities/espace_locataire.dart';
import '../../domain/repositories/espace_locataire_repository.dart';
import '../datasources/espace_locataire_remote_datasource.dart';

class EspaceLocataireRepositoryImpl implements EspaceLocataireRepository {
  final EspaceLocataireRemoteDataSource remoteDataSource;
  EspaceLocataireRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<LogementLocataire>>> accueil() =>
      appelApi(() => remoteDataSource.accueil());

  @override
  Future<Either<Failure, List<LogementLocataire>>> logements() =>
      appelApi(() => remoteDataSource.logements());

  @override
  Future<Either<Failure, PageResultat<Echeance>>> echeances({
    required int page,
    required bool aPayer,
  }) => appelApi(() => remoteDataSource.echeances(page: page, aPayer: aPayer));

  @override
  Future<Either<Failure, PageResultat<Paiement>>> paiements({
    required int page,
  }) => appelApi(() => remoteDataSource.paiements(page: page));

  @override
  Future<Either<Failure, PageResultat<TransactionPaiement>>> transactions({
    required int page,
  }) => appelApi(() => remoteDataSource.transactions(page: page));

  @override
  Future<Either<Failure, TransactionPaiement>> transaction(String id) =>
      appelApi(() => remoteDataSource.transaction(id));

  @override
  Future<Either<Failure, MoyensPaiementLocataire>> moyensPaiement(
    String bailId,
  ) => appelApi(() => remoteDataSource.moyensPaiement(bailId));

  @override
  Future<Either<Failure, DemandePaiement>> payer({
    String? echeanceId,
    String? chargeId,
    required String portefeuille,
    int? montant,
  }) => appelApi(
    () => remoteDataSource.payer(
      echeanceId: echeanceId,
      chargeId: chargeId,
      portefeuille: portefeuille,
      montant: montant,
    ),
  );

  @override
  Future<Either<Failure, void>> declarerPreuve(
    Map<String, dynamic> champs, {
    String? capture,
  }) =>
      appelApi(() => remoteDataSource.declarerPreuve(champs, capture: capture));

  @override
  Future<Either<Failure, List<Caution>>> cautions() =>
      appelApi(() => remoteDataSource.cautions());

  @override
  Future<Either<Failure, void>> contesterRetenue(
    String mouvementId,
    String message,
  ) => appelApi(() => remoteDataSource.contesterRetenue(mouvementId, message));

  @override
  Future<Either<Failure, PageResultat<ChargeRefacturee>>> charges({
    required int page,
  }) => appelApi(() => remoteDataSource.charges(page: page));

  @override
  Future<Either<Failure, ChargeRefacturee>> charge(String id) =>
      appelApi(() => remoteDataSource.charge(id));

  @override
  Future<Either<Failure, AccordsLocataire>> accords() =>
      appelApi(remoteDataSource.accords);

  @override
  Future<Either<Failure, void>> action(
    String chemin, {
    Map<String, dynamic> corps = const {},
  }) => appelApi(() => remoteDataSource.action(chemin, corps: corps));

  @override
  Future<Either<Failure, Uint8List>> recuPaiement(String id) =>
      appelApi(() => remoteDataSource.recuPaiement(id));

  @override
  Future<Either<Failure, void>> consentementWhatsapp({required bool accorde}) =>
      appelApi(() => remoteDataSource.consentementWhatsapp(accorde: accorde));

  @override
  Future<Either<Failure, PageResultat<Incident>>> incidents({
    required int page,
  }) => appelApi(() => remoteDataSource.incidents(page: page));

  @override
  Future<Either<Failure, Incident>> incident(String id) =>
      appelApi(() => remoteDataSource.incident(id));

  @override
  Future<Either<Failure, Incident>> signaler(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.signaler(corps, cle: cle));

  @override
  Future<Either<Failure, void>> ajouterPieceIncident(
    String id,
    String chemin,
  ) => appelApi(() => remoteDataSource.ajouterPieceIncident(id, chemin));

  @override
  Future<Either<Failure, PageResultat<EtatDesLieux>>> etatsDesLieux({
    required int page,
  }) => appelApi(() => remoteDataSource.etatsDesLieux(page: page));

  @override
  Future<Either<Failure, EtatDesLieux>> etatDesLieux(String id) =>
      appelApi(() => remoteDataSource.etatDesLieux(id));

  @override
  Future<Either<Failure, Uint8List>> pdfEtatDesLieux(String id) =>
      appelApi(() => remoteDataSource.pdfEtatDesLieux(id));

  @override
  Future<Either<Failure, void>> accepterEtatDesLieux(String id) =>
      appelApi(() => remoteDataSource.accepterEtatDesLieux(id));

  @override
  Future<Either<Failure, void>> contesterEtatDesLieux(
    String id,
    String commentaire,
  ) => appelApi(() => remoteDataSource.contesterEtatDesLieux(id, commentaire));
}
