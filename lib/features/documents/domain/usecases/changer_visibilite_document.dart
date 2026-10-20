import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/documents_repository.dart';

class ChangerVisibiliteDocument {
  final DocumentsRepository repository;
  ChangerVisibiliteDocument(this.repository);

  Future<Either<Failure, void>> call(String id, {required bool visible}) =>
      repository.changerVisibilite(id, visible: visible);
}
