import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/resultat_connexion.dart';
import '../repositories/auth_repository.dart';

class Connecter {
  final AuthRepository repository;
  Connecter(this.repository);

  Future<Either<Failure, ResultatConnexion>> call(
          {required String identifiant, required String motDePasse}) =>
      repository.connecter(identifiant: identifiant, motDePasse: motDePasse);
}
