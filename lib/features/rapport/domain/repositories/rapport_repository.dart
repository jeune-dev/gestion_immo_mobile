import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/rapports.dart';

abstract class RapportRepository {
  Future<Either<Failure, RapportFinancier>> financier(
      {required String du, required String au});
  Future<Either<Failure, RapportImmobilier>> immobilier(
      {required String du, required String au});
  Future<Either<Failure, RapportLocataires>> locataires(
      {required String du, required String au});
  Future<Either<Failure, RapportTravaux>> travaux(
      {required String du, required String au});
  Future<Either<Failure, PageResultat<LigneRentabilite>>> rentabilite(
      {required int page, required String du, required String au});
  Future<Either<Failure, Uint8List>> exporterCsv(String type,
      {required String du, required String au});
}
