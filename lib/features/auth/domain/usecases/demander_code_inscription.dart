import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../repositories/auth_repository.dart';

/// Inscription, étape 1 : un code à 6 chiffres part à l'adresse saisie.
class DemanderCodeInscription {
  final AuthRepository repository;
  DemanderCodeInscription(this.repository);

  Future<Either<Failure, void>> call(String email, {String? prenom}) =>
      repository.demanderCodeInscription(email, prenom: prenom);
}
