import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../repositories/auth_repository.dart';

/// Inscription, étape 2 : rend le jeton qui atteste que l'adresse a été
/// vérifiée. Le compte n'est créé qu'ensuite, sur présentation de ce jeton.
class VerifierCodeInscription {
  final AuthRepository repository;
  VerifierCodeInscription(this.repository);

  Future<Either<Failure, String>> call(String email, String code) =>
      repository.verifierCodeInscription(email, code);
}
