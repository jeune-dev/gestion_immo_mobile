import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/documents_repository.dart';

class TelechargerDocument {
  final DocumentsRepository repository;
  TelechargerDocument(this.repository);

  Future<Either<Failure, Uint8List>> call(String id, {String? taille}) =>
      repository.telecharger(id, taille: taille);
}
