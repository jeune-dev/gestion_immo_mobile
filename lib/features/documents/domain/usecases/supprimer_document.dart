import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/documents_repository.dart';

class SupprimerDocument {
  final DocumentsRepository repository;
  SupprimerDocument(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.supprimerDocument(id);
}
