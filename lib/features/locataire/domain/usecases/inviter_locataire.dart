import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/locataire.dart';
import '../repositories/locataire_repository.dart';

/// Générer un nouveau code d'invitation pour l'application.
class InviterLocataire {
  final LocataireRepository repository;
  InviterLocataire(this.repository);

  Future<Either<Failure, Invitation>> call(String id) =>
      repository.inviterLocataire(id);
}
