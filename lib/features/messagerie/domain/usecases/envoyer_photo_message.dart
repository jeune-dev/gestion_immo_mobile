import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/messagerie.dart';
import '../repositories/messagerie_repository.dart';

class EnvoyerPhotoMessage {
  final MessagerieRepository repository;
  EnvoyerPhotoMessage(this.repository);

  Future<Either<Failure, Message>> call(String chemin,
          {String? filId, String? locataireId}) =>
      repository.envoyerPhoto(chemin, filId: filId, locataireId: locataireId);
}
