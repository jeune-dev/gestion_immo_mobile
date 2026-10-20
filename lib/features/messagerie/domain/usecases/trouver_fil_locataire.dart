import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/messagerie_repository.dart';

class TrouverFilLocataire {
  final MessagerieRepository repository;
  TrouverFilLocataire(this.repository);

  Future<Either<Failure, String?>> call(String locataireId) =>
      repository.filAvecLocataire(locataireId);
}
