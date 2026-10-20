import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/documents_repository.dart';

class AjouterPhotoDocument {
  final DocumentsRepository repository;
  AjouterPhotoDocument(this.repository);

  Future<Either<Failure, void>> call(
          {required String type, required String id, required String chemin}) =>
      repository.ajouterPhoto(type: type, id: id, chemin: chemin);
}
