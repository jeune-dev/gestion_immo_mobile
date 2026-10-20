import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/espace_locataire.dart';
import '../repositories/espace_locataire_repository.dart';

class GetAccueilLocataire {
  final EspaceLocataireRepository repository;
  GetAccueilLocataire(this.repository);

  Future<Either<Failure, List<LogementLocataire>>> call() =>
      repository.accueil();
}
