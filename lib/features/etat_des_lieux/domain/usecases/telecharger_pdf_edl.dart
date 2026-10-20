import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class TelechargerPdfEdl {
  final EtatDesLieuxRepository repository;
  TelechargerPdfEdl(this.repository);

  Future<Either<Failure, Uint8List>> call(String id) => repository.pdf(id);
}
