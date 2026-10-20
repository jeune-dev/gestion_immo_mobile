import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

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
  Future<Either<Failure, List<LogementLocataire>>> accueil() async {
    try {
      final logementLocataires = await remoteDataSource.accueil();
      return Right(logementLocataires);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<LogementLocataire>>> logements() async {
    try {
      final logementLocataires = await remoteDataSource.logements();
      return Right(logementLocataires);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<Echeance>>> echeances(
      {required int page, required bool aPayer}) async {
    try {
      final echeances =
          await remoteDataSource.echeances(page: page, aPayer: aPayer);
      return Right(echeances);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<Paiement>>> paiements(
      {required int page}) async {
    try {
      final paiements = await remoteDataSource.paiements(page: page);
      return Right(paiements);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<TransactionPaiement>>> transactions(
      {required int page}) async {
    try {
      final transactionPaiements =
          await remoteDataSource.transactions(page: page);
      return Right(transactionPaiements);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, TransactionPaiement>> transaction(String id) async {
    try {
      final transactionPaiement = await remoteDataSource.transaction(id);
      return Right(transactionPaiement);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, MoyensPaiementLocataire>> moyensPaiement(
      String bailId) async {
    try {
      final moyensPaiementLocataire =
          await remoteDataSource.moyensPaiement(bailId);
      return Right(moyensPaiementLocataire);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, DemandePaiement>> payer(
      {String? echeanceId,
      String? chargeId,
      required String portefeuille,
      int? montant}) async {
    try {
      final demandePaiement = await remoteDataSource.payer(
          echeanceId: echeanceId,
          chargeId: chargeId,
          portefeuille: portefeuille,
          montant: montant);
      return Right(demandePaiement);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> declarerPreuve(Map<String, dynamic> champs,
      {String? capture}) async {
    try {
      await remoteDataSource.declarerPreuve(champs, capture: capture);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<Caution>>> cautions() async {
    try {
      final cautions = await remoteDataSource.cautions();
      return Right(cautions);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> contesterRetenue(
      String mouvementId, String message) async {
    try {
      await remoteDataSource.contesterRetenue(mouvementId, message);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<ChargeRefacturee>>> charges(
      {required int page}) async {
    try {
      final chargeRefacturees = await remoteDataSource.charges(page: page);
      return Right(chargeRefacturees);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> consentementWhatsapp(
      {required bool accorde}) async {
    try {
      await remoteDataSource.consentementWhatsapp(accorde: accorde);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<Incident>>> incidents(
      {required int page}) async {
    try {
      final incidents = await remoteDataSource.incidents(page: page);
      return Right(incidents);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Incident>> incident(String id) async {
    try {
      final incident = await remoteDataSource.incident(id);
      return Right(incident);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Incident?>> signalerOuDifferer(
      Map<String, dynamic> corps) async {
    try {
      final incident = await remoteDataSource.signalerOuDifferer(corps);
      return Right(incident);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterPieceIncident(
      String id, String chemin) async {
    try {
      await remoteDataSource.ajouterPieceIncident(id, chemin);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<EtatDesLieux>>> etatsDesLieux(
      {required int page}) async {
    try {
      final etatDesLieuxs = await remoteDataSource.etatsDesLieux(page: page);
      return Right(etatDesLieuxs);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, EtatDesLieux>> etatDesLieux(String id) async {
    try {
      final etatDesLieux = await remoteDataSource.etatDesLieux(id);
      return Right(etatDesLieux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> pdfEtatDesLieux(String id) async {
    try {
      final octets = await remoteDataSource.pdfEtatDesLieux(id);
      return Right(octets);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> accepterEtatDesLieux(String id) async {
    try {
      await remoteDataSource.accepterEtatDesLieux(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> contesterEtatDesLieux(
      String id, String commentaire) async {
    try {
      await remoteDataSource.contesterEtatDesLieux(id, commentaire);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
