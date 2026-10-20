import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/espace_locataire_repository.dart';

class TelechargerMonEtatDesLieux {
  final EspaceLocataireRepository repository;
  TelechargerMonEtatDesLieux(this.repository);

  Future<Either<Failure, Uint8List>> call(String id) =>
      repository.pdfEtatDesLieux(id);
}
