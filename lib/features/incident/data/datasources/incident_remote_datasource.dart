import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/features/documents/data/models/document_model.dart';
import '../models/incident_model.dart';

abstract class IncidentRemoteDataSource {
  Future<PageResultat<IncidentModel>> getIncidents(
      {required int page, String? statut});
  Future<IncidentModel> getIncident(String id);

  /// Photos et vidéos jointes par le locataire.
  Future<List<DocumentModel>> pieces(String id);
  Future<IncidentModel> creerIncident(Map<String, dynamic> corps,
      {required String cle});

  /// `analyser`, `resoudre` ou `rejeter`.
  Future<void> traiter(String id, String action, Map<String, dynamic> corps);
  Future<void> planifierTravaux(String id, Map<String, dynamic> corps,
      {required String cle});
}

class IncidentRemoteDataSourceImpl implements IncidentRemoteDataSource {
  final ApiClient api;
  IncidentRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<IncidentModel>> getIncidents(
          {required int page, String? statut}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.incidents,
            query: {'page': page, 'status': statut, 'tri': '-created_at'}),
        IncidentModel.fromJson,
      );

  @override
  Future<IncidentModel> getIncident(String id) async =>
      IncidentModel.fromJson(Map<String, dynamic>.from((await api
              .get<Map<String, dynamic>>(ApiEndpoints.incident(id)))['incident']
          as Map));

  @override
  Future<List<DocumentModel>> pieces(String id) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.documents,
            query: {'entity_type': 'incident', 'entity_id': id}),
        DocumentModel.fromJson,
      ).items;

  @override
  Future<IncidentModel> creerIncident(Map<String, dynamic> corps,
          {required String cle}) async =>
      IncidentModel.fromJson(
        Map<String, dynamic>.from((await api.post<Map<String, dynamic>>(
            ApiEndpoints.incidents,
            body: corps,
            idempotence: cle))['incident'] as Map),
      );

  @override
  Future<void> traiter(String id, String action, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.incidentAction(id, action), body: corps);

  @override
  Future<void> planifierTravaux(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.incidentTravaux(id),
          body: corps, idempotence: cle);
}
