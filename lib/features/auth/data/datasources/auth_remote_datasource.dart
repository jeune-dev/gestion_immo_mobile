import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/compte_model.dart';

/// Appels d'authentification (contrat § 5). Le client mobile n'envoie pas
/// d'en-tête Origin : le refresh token arrive dans le corps.
abstract class AuthRemoteDataSource {
  /// Renvoie la réponse brute : jetons, ou `{ mfa_requis, mfa_token }`.
  Future<Map<String, dynamic>> connecter(Map<String, dynamic> corps);
  Future<Map<String, dynamic>> verifierMfa(Map<String, dynamic> corps);
  Future<Map<String, dynamic>> inscrire(Map<String, dynamic> corps);
  Future<Map<String, dynamic>> activerLocataire(Map<String, dynamic> corps);
  Future<Map<String, dynamic>> changerMotDePasse(Map<String, dynamic> corps);
  Future<CompteModel> lireCompte();
  Future<void> deconnecter(String? refreshToken);
  Future<void> demanderReinitialisation(String identifiant);
  Future<void> reinitialiserMotDePasse(Map<String, dynamic> corps);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient api;
  AuthRemoteDataSourceImpl({required this.api});

  @override
  Future<Map<String, dynamic>> connecter(Map<String, dynamic> corps) =>
      api.post<Map<String, dynamic>>(ApiEndpoints.connexion,
          body: corps, sansJeton: true);

  @override
  Future<Map<String, dynamic>> verifierMfa(Map<String, dynamic> corps) =>
      api.post<Map<String, dynamic>>(ApiEndpoints.mfa,
          body: corps, sansJeton: true);

  @override
  Future<Map<String, dynamic>> inscrire(Map<String, dynamic> corps) =>
      api.post<Map<String, dynamic>>(ApiEndpoints.inscription,
          body: corps, sansJeton: true);

  @override
  Future<Map<String, dynamic>> activerLocataire(Map<String, dynamic> corps) =>
      api.post<Map<String, dynamic>>(ApiEndpoints.activationLocataire,
          body: corps, sansJeton: true);

  @override
  Future<Map<String, dynamic>> changerMotDePasse(Map<String, dynamic> corps) =>
      api.post<Map<String, dynamic>>(ApiEndpoints.compteMotDePasse,
          body: corps);

  @override
  Future<CompteModel> lireCompte() async => CompteModel.fromJson(
      await api.get<Map<String, dynamic>>(ApiEndpoints.compte));

  @override
  Future<void> deconnecter(String? refreshToken) =>
      api.post<dynamic>(ApiEndpoints.deconnexion,
          body: {'refresh_token': refreshToken}, sansJeton: true);

  @override
  Future<void> demanderReinitialisation(String identifiant) =>
      api.post<dynamic>(ApiEndpoints.motDePasseOublie,
          body: {'identifiant': identifiant}, sansJeton: true);

  @override
  Future<void> reinitialiserMotDePasse(Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.reinitialiserMotDePasse,
          body: corps, sansJeton: true);
}
