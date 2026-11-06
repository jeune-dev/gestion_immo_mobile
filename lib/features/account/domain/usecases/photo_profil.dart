import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../repositories/account_repository.dart';

/// Photo de profil du compte connecté, gardée par le serveur.
class LirePhotoProfil {
  final AccountRepository repository;
  LirePhotoProfil(this.repository);

  Future<Either<Failure, Uint8List>> call() => repository.lirePhoto();
}

class EnvoyerPhotoProfil {
  final AccountRepository repository;
  EnvoyerPhotoProfil(this.repository);

  Future<Either<Failure, void>> call(String chemin) =>
      repository.envoyerPhoto(chemin);
}

class SupprimerPhotoProfil {
  final AccountRepository repository;
  SupprimerPhotoProfil(this.repository);

  Future<Either<Failure, void>> call() => repository.supprimerPhoto();
}
