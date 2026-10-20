import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/messagerie.dart';
import '../repositories/messagerie_repository.dart';

class GetMessages {
  final MessagerieRepository repository;
  GetMessages(this.repository);

  Future<Either<Failure, List<Message>>> call(String filId,
          {bool espaceLocataire = false}) =>
      repository.messages(filId, espaceLocataire: espaceLocataire);
}
