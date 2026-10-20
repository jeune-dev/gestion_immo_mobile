import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../../domain/entities/rapports.dart';
import '../../domain/repositories/rapport_repository.dart';
import '../datasources/rapport_remote_datasource.dart';
import '../models/rapports_model.dart';

class RapportRepositoryImpl implements RapportRepository {
  final RapportRemoteDataSource remoteDataSource;
  RapportRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, RapportFinancier>> financier(
      {required String du, required String au}) async {
    try {
      final rapportFinancier = RapportsModel.financier(
          await remoteDataSource.rapport('financier', du: du, au: au));
      return Right(rapportFinancier);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, RapportImmobilier>> immobilier(
      {required String du, required String au}) async {
    try {
      final rapportImmobilier = RapportsModel.immobilier(
          await remoteDataSource.rapport('immobilier', du: du, au: au));
      return Right(rapportImmobilier);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, RapportLocataires>> locataires(
      {required String du, required String au}) async {
    try {
      final rapportLocataires = RapportsModel.locataires(
          await remoteDataSource.rapport('locataires', du: du, au: au));
      return Right(rapportLocataires);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, RapportTravaux>> travaux(
      {required String du, required String au}) async {
    try {
      final rapportTravaux = RapportsModel.travaux(
          await remoteDataSource.rapport('travaux', du: du, au: au));
      return Right(rapportTravaux);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, PageResultat<LigneRentabilite>>> rentabilite(
      {required int page, required String du, required String au}) async {
    try {
      final ligneRentabilites =
          await remoteDataSource.rentabilite(page: page, du: du, au: au);
      return Right(ligneRentabilites);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exporterCsv(String type,
      {required String du, required String au}) async {
    try {
      final octets = await remoteDataSource.exporterCsv(type, du: du, au: au);
      return Right(octets);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
