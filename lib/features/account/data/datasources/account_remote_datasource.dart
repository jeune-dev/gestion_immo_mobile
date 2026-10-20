import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/session_appareil_model.dart';

abstract class AccountRemoteDataSource {
  Future<void> modifierProfil(Map<String, dynamic> corps);
  Future<List<SessionAppareilModel>> sessions();
  Future<void> revoquerSession(String id);
  Future<void> revoquerToutes();
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
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.compteSessions,
        cache: false);
    return ((r['sessions'] as List?) ?? const [])
        .map((e) =>
            SessionAppareilModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> revoquerSession(String id) =>
      api.delete<dynamic>(ApiEndpoints.compteSession(id));

  @override
  Future<void> revoquerToutes() =>
      api.post<dynamic>(ApiEndpoints.compteRevoquerToutes);

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
