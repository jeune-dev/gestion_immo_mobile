import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/session_appareil_model.dart';

abstract class AccountRemoteDataSource {
  Future<void> modifierProfil(Map<String, dynamic> corps);
  Future<List<SessionAppareilModel>> sessions();
  Future<void> revoquerSession(String id);

  /// Ferme toutes les sessions sauf celle de cet appareil.
  Future<void> revoquerAutres();
  Future<SecretMfaModel> initialiserMfa(String motDePasse);

  /// Nouvelle session (jetons) + codes de secours.
  Future<Map<String, dynamic>> activerMfa(String code);
  Future<void> desactiverMfa(
      {required String motDePasse, required String code});
  Future<List<String>> regenererCodesSecours(
      {required String motDePasse, required String code});
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final ApiClient api;
  AccountRemoteDataSourceImpl({required this.api});

  @override
  Future<void> modifierProfil(Map<String, dynamic> corps) =>
      api.patch<dynamic>(ApiEndpoints.compte, body: corps);

  @override
  Future<List<SessionAppareilModel>> sessions() async {
    // Le refresh token présenté permet au serveur de marquer la session courante.
    final refresh = await api.session.lireRefresh();
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.compteSessions,
        cache: false,
        headers: refresh != null ? {'X-Refresh-Token': refresh} : null);
    return ((r['sessions'] as List?) ?? const [])
        .map((e) =>
            SessionAppareilModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> revoquerSession(String id) =>
      api.delete<dynamic>(ApiEndpoints.compteSession(id));

  /// `POST /compte/sessions/revoquer-toutes` fermerait AUSSI cette session :
  /// on ferme donc une à une les sessions qui ne sont pas « cet appareil ».
  @override
  Future<void> revoquerAutres() async {
    final liste = await sessions();
    if (!liste.any((s) => s.courante)) {
      throw ApiException(
          'Impossible de reconnaître cet appareil parmi les sessions. Réessayez.',
          code: 'SESSION_COURANTE_INCONNUE');
    }
    for (final s in liste.where((s) => !s.courante)) {
      await revoquerSession(s.id);
    }
  }

  @override
  Future<SecretMfaModel> initialiserMfa(String motDePasse) async =>
      SecretMfaModel.fromJson(await api.post<Map<String, dynamic>>(
          ApiEndpoints.mfaInitialiser,
          body: {'current_password': motDePasse}));

  @override
  Future<Map<String, dynamic>> activerMfa(String code) =>
      api.post<Map<String, dynamic>>(ApiEndpoints.mfaActiver,
          body: {'code': code});

  @override
  Future<void> desactiverMfa(
          {required String motDePasse, required String code}) =>
      api.post<dynamic>(ApiEndpoints.mfaDesactiver,
          body: {'current_password': motDePasse, 'code': code});

  @override
  Future<List<String>> regenererCodesSecours(
      {required String motDePasse, required String code}) async {
    final r = await api.post<Map<String, dynamic>>(ApiEndpoints.mfaCodesSecours,
        body: {'current_password': motDePasse, 'code': code});
    return ((r['codes_secours'] as List?) ?? const []).cast<String>();
  }
}
