import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/espace_locataire.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMoyensPaiementLocataire {
  final EspaceLocataireRepository repository;
  GetMoyensPaiementLocataire(this.repository);

  Future<Either<Failure, MoyensPaiementLocataire>> call(String bailId) =>
      repository.moyensPaiement(bailId);
}
