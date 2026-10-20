import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/rapport_repository.dart';

class ExporterRapportCsv {
  final RapportRepository repository;
  ExporterRapportCsv(this.repository);

  Future<Either<Failure, Uint8List>> call(String type,
          {required String du, required String au}) =>
      repository.exporterCsv(type, du: du, au: au);
}
