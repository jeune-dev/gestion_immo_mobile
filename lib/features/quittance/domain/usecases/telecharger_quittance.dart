import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/quittance_repository.dart';

class TelechargerQuittance {
  final QuittanceRepository repository;
  TelechargerQuittance(this.repository);

  Future<Either<Failure, Uint8List>> call(String id,
          {bool espaceLocataire = false}) =>
      repository.pdf(id, espaceLocataire: espaceLocataire);
}
