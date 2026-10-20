import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/quittance.dart';

abstract class QuittanceRepository {
  Future<Either<Failure, PageResultat<Quittance>>> getQuittances(
      {required int page, required bool espaceLocataire});
  Future<Either<Failure, Uint8List>> pdf(String id,
      {required bool espaceLocataire});
}
