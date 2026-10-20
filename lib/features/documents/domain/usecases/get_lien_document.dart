import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/document_app.dart';
import '../repositories/documents_repository.dart';

class GetLienDocument {
  final DocumentsRepository repository;
  GetLienDocument(this.repository);

  Future<Either<Failure, LienDocument>> call(String id) => repository.lien(id);
}
