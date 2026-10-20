import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/compte.dart';
import '../entities/resultat_connexion.dart';

abstract class AuthRepository {
  /// Vrai si une session existe sur l'appareil (refresh token dans le coffre).
  Future<bool> sessionEnregistree();

  /// Renouvelle la session au lancement. `false` : refus explicite du serveur.
  Future<bool> restaurerSession();

  Future<Either<Failure, ResultatConnexion>> connecter(
      {required String identifiant, required String motDePasse});
  Future<Either<Failure, void>> verifierMfa(
      {required String jeton, String? code, String? codeSecours});
  Future<Either<Failure, void>> inscrireProprietaire(
      Map<String, dynamic> corps);
  Future<Either<Failure, void>> activerLocataire(Map<String, dynamic> corps);
  Future<Either<Failure, void>> changerMotDePasse(
      {required String actuel, required String nouveau});
  Future<Either<Failure, Compte>> lireCompte();

  /// Ferme la session : côté serveur si possible, puis sur l'appareil (jetons, cache, file hors ligne).
  Future<void> deconnecter();

  Future<Either<Failure, void>> demanderReinitialisation(String identifiant);
  Future<Either<Failure, void>> reinitialiserMotDePasse(
      Map<String, dynamic> corps);
}
