import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/paiement.dart';
import '../../domain/repositories/paiement_repository.dart';
import '../datasources/paiement_remote_datasource.dart';

class PaiementRepositoryImpl implements PaiementRepository {
  final PaiementRemoteDataSource remoteDataSource;
  PaiementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, int>> encaisser(Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      final resultat = await remoteDataSource.encaisser(corps, cle: cle);
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<Paiement>>> getPaiements(
      {required int page, String? moyen}) async {
    try {
      final paiements =
          await remoteDataSource.getPaiements(page: page, moyen: moyen);
      return Right(paiements);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, FichePaiement>> getFichePaiement(String id) async {
    try {
      final (paiement, quittances) = await (
        remoteDataSource.getPaiement(id),
        remoteDataSource.quittances(id)
      ).wait;
      return Right(FichePaiement(paiement: paiement, quittances: quittances));
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> rembourser(
      String id, Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.rembourser(id, corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<TransactionPaiement>>> transactions(
      {required int page,
      String? statut,
      bool preuvesSeulement = false}) async {
    try {
      final transactionPaiements = await remoteDataSource.transactions(
          page: page, statut: statut, preuvesSeulement: preuvesSeulement);
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
  Future<Either<Failure, void>> validerTransaction(String id) async {
    try {
      await remoteDataSource.validerTransaction(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> rejeterTransaction(
      String id, String motif) async {
    try {
      await remoteDataSource.rejeterTransaction(id, motif);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<Rapprochement>>> rapprochements(
      {required int page, String? statut}) async {
    try {
      final rapprochements =
          await remoteDataSource.rapprochements(page: page, statut: statut);
      return Right(rapprochements);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> resoudreRapprochement(
      String id, Map<String, dynamic> corps,
      {required String cle}) async {
    try {
      await remoteDataSource.resoudreRapprochement(id, corps, cle: cle);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> rejeterRapprochement(
      String id, Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.rejeterRapprochement(id, corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, List<MoyenPaiement>>> moyens() async {
    try {
      final resultat = await remoteDataSource.moyens();
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> configurerMoyen(
      Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.configurerMoyen(corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
