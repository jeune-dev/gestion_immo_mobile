import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/messagerie.dart';
import '../repositories/messagerie_repository.dart';

class EnvoyerMessage {
  final MessagerieRepository repository;
  EnvoyerMessage(this.repository);

  Future<Either<Failure, Message>> call(String texte,
          {String? filId, String? locataireId}) =>
      repository.envoyerTexte(texte, filId: filId, locataireId: locataireId);
}
