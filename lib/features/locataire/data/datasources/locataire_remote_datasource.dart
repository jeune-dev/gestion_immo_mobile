import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/locataire_model.dart';

abstract class LocataireRemoteDataSource {
  Future<PageResultat<LocataireModel>> getLocataires({
    required int page,
    String? recherche,
  });
  Future<LocataireModel> getLocataire(String id);

  /// Le locataire créé, et son code d'invitation s'il a été demandé.
  Future<(LocataireModel, InvitationModel?)> creerLocataire(
    Map<String, dynamic> data, {
    required String cle,
  });
  Future<LocataireModel> modifierLocataire(
      String id, Map<String, dynamic> data);
  Future<void> supprimerLocataire(String id);
  Future<InvitationModel> inviterLocataire(String id);
  Future<void> enregistrerConsentementWhatsapp(
    String id, {
    required bool accorde,
  });
}

class LocataireRemoteDataSourceImpl implements LocataireRemoteDataSource {
  final ApiClient api;
  LocataireRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<LocataireModel>> getLocataires({
    required int page,
    String? recherche,
  }) async {
    final data = await api.get<Map<String, dynamic>>(
      ApiEndpoints.locataires,
      query: {'page': page, 'q': recherche, 'tri': 'last_name'},
    );
    return PageResultat.depuisJson(data, LocataireModel.fromJson);
  }

  @override
  Future<LocataireModel> getLocataire(String id) async {
    final data = await api.get<Map<String, dynamic>>(
      ApiEndpoints.locataire(id),
    );
    return _parseLocataire(data);
  }

  @override
  Future<(LocataireModel, InvitationModel?)> creerLocataire(
    Map<String, dynamic> data, {
    required String cle,
  }) async {
    final response = await api.post<Map<String, dynamic>>(
      ApiEndpoints.locataires,
      body: data,
      idempotence: cle,
    );
    return (
      _parseLocataire(response),
      InvitationModel.fromJsonOuNull(response['invitation']),
    );
  }

  @override
  Future<LocataireModel> modifierLocataire(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await api.patch<Map<String, dynamic>>(
      ApiEndpoints.locataire(id),
      body: data,
    );
    return _parseLocataire(response);
  }

  @override
  Future<void> supprimerLocataire(String id) async {
    await api.delete<dynamic>(ApiEndpoints.locataire(id));
  }

  @override
  Future<InvitationModel> inviterLocataire(String id) async {
    final response = await api.post<Map<String, dynamic>>(
      ApiEndpoints.locataireInvitation(id),
    );
    return InvitationModel.fromJsonOuNull(response['invitation'])!;
  }

  @override
  Future<void> enregistrerConsentementWhatsapp(
    String id, {
    required bool accorde,
  }) async {
    await api.post<dynamic>(
      ApiEndpoints.locataireConsentement(id),
      body: {'accorde': accorde},
    );
  }

  // L'API renvoie le locataire sous la clé `tenant`.
  LocataireModel _parseLocataire(Map<String, dynamic> data) =>
      LocataireModel.fromJson(Map<String, dynamic>.from(data['tenant'] as Map));
}
