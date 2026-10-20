import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/document_app.dart';
import '../repositories/documents_repository.dart';

class GetDocuments {
  final DocumentsRepository repository;
  GetDocuments(this.repository);

  Future<Either<Failure, PageResultat<DocumentApp>>> call(
          {required String type, required String id}) =>
      repository.getDocuments(type: type, id: id);
}
