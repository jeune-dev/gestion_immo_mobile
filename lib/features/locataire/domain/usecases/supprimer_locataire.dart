import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/locataire_repository.dart';

class SupprimerLocataire {
  final LocataireRepository repository;
  SupprimerLocataire(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.supprimerLocataire(id);
}
