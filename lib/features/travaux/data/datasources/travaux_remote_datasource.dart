import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/travaux_model.dart';

abstract class TravauxRemoteDataSource {
  Future<PageResultat<TravauxModel>> getListeTravaux(
      {required int page, String? statut});
  Future<TravauxModel> getTravaux(String id);
  Future<TravauxModel> creerTravaux(Map<String, dynamic> corps,
      {required String cle});
  Future<TravauxModel> modifierTravaux(String id, Map<String, dynamic> corps);
  Future<void> changerStatutTravaux(String id, Map<String, dynamic> corps);
  Future<void> ajouterPhoto(String id,
      {required String phase, required String chemin});
  Future<void> supprimerPhoto(String id, String photoId);
}

class TravauxRemoteDataSourceImpl implements TravauxRemoteDataSource {
  final ApiClient api;
  TravauxRemoteDataSourceImpl({required this.api});

  TravauxModel _travaux(Map<String, dynamic> r) =>
      TravauxModel.fromJson(Map<String, dynamic>.from(r['work_order'] as Map));

  @override
  Future<PageResultat<TravauxModel>> getListeTravaux(
          {required int page, String? statut}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.travaux,
            query: {'page': page, 'status': statut, 'tri': '-created_at'}),
        TravauxModel.fromJson,
      );

  @override
  Future<TravauxModel> getTravaux(String id) async =>
      _travaux(await api.get<Map<String, dynamic>>(ApiEndpoints.travail(id)));

  @override
  Future<TravauxModel> creerTravaux(Map<String, dynamic> corps,
          {required String cle}) async =>
      _travaux(await api.post<Map<String, dynamic>>(ApiEndpoints.travaux,
          body: corps, idempotence: cle));

  @override
  Future<TravauxModel> modifierTravaux(
          String id, Map<String, dynamic> corps) async =>
      _travaux(await api.patch<Map<String, dynamic>>(ApiEndpoints.travail(id),
          body: corps));

  @override
  Future<void> changerStatutTravaux(String id, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.travauxStatut(id), body: corps);

  /// Horodatage de la prise de vue ET horodatage serveur conservés (§ 19).
  @override
  Future<void> ajouterPhoto(String id,
          {required String phase, required String chemin}) =>
      api.upload<dynamic>(
        ApiEndpoints.travauxPhotos(id),
        cheminFichier: chemin,
        champs: {
          'phase': phase,
          'captured_at': DateTime.now().toUtc().toIso8601String()
        },
        idempotence: nouvelleCle(),
      );

  @override
  Future<void> supprimerPhoto(String id, String photoId) =>
      api.delete<dynamic>(ApiEndpoints.travauxPhoto(id, photoId));
}
