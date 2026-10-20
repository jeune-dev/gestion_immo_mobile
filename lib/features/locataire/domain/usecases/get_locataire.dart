import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/locataire.dart';
import '../repositories/locataire_repository.dart';

/// Ouvrir la fiche d'un locataire : ses baux, son solde, ses paiements.
class GetLocataire {
  final LocataireRepository repository;
  GetLocataire(this.repository);

  Future<Either<Failure, Locataire>> call(String id) =>
      repository.getLocataire(id);
}
