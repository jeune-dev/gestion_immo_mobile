import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/etat_des_lieux.dart';
import '../../domain/repositories/etat_des_lieux_repository.dart';
import '../datasources/etat_des_lieux_remote_datasource.dart';

class EtatDesLieuxRepositoryImpl implements EtatDesLieuxRepository {
  final EtatDesLieuxRemoteDataSource remoteDataSource;
  EtatDesLieuxRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<EtatDesLieux>>> getEtatsDesLieux(
      {required int page}) async {
    try {
      final etatDesLieuxs = await remoteDataSource.getEtatsDesLieux(page: page);
      return Right(etatDesLieuxs);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, EtatDesLieux>> getEtatDesLieux(String id) async {
    try {
      final etatDesLieux = await remoteDataSource.getEtatDesLieux(id);
      return Right(etatDesLieux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, EtatDesLieux>> creerEtatDesLieux(
      Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      final etatDesLieux =
          await remoteDataSource.creerEtatDesLieux(corps, cle: cle);
      return Right(etatDesLieux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> modifierEtatDesLieux(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.modifierEtatDesLieux(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerEtatDesLieux(String id) async {
    try {
      await remoteDataSource.supprimerEtatDesLieux(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> enregistrerSaisie(
      String id, List<Map<String, dynamic>> elements) async {
    try {
      await remoteDataSource.enregistrerSaisie(id, elements);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterPiece(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.ajouterPiece(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> modifierPiece(
      String id, String pieceId, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.modifierPiece(id, pieceId, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerPiece(
      String id, String pieceId) async {
    try {
      await remoteDataSource.supprimerPiece(id, pieceId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterElement(
      String id, String pieceId, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.ajouterElement(id, pieceId, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> modifierElement(
      String id, String elementId, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.modifierElement(id, elementId, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerElement(
      String id, String elementId) async {
    try {
      await remoteDataSource.supprimerElement(id, elementId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterPhoto(
      String id, String elementId, String chemin) async {
    try {
      await remoteDataSource.ajouterPhoto(id, elementId, chemin);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerPhoto(
      String id, String photoId) async {
    try {
      await remoteDataSource.supprimerPhoto(id, photoId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> soumettre(String id) async {
    try {
      await remoteDataSource.soumettre(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, EtatDesLieux>> corriger(String id) async {
    try {
      final etatDesLieux = await remoteDataSource.corriger(id);
      return Right(etatDesLieux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> pdf(String id) async {
    try {
      final octets = await remoteDataSource.pdf(id);
      return Right(octets);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, ComparaisonEdl>> comparaison(String bailId) async {
    try {
      final comparaisonEdl = await remoteDataSource.comparaison(bailId);
      return Right(comparaisonEdl);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
