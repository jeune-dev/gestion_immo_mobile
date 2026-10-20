import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/caution_model.dart';

/// Mouvements d'argent : Idempotency-Key OBLIGATOIRE (versements, retenues, restitutions).
abstract class CautionRemoteDataSource {
  Future<PageResultat<CautionModel>> getCautions(
      {required int page, String? statut});
  Future<CautionModel> getCaution(String id);
  Future<void> verser(String id, Map<String, dynamic> corps,
      {required String cle});
  Future<void> restituer(String id, Map<String, dynamic> corps,
      {required String cle});

  /// Renvoie l'identifiant du document justificatif.
  Future<String> ajouterJustificatif(String id, String chemin);
  Future<void> retenir(String id, Map<String, dynamic> corps,
      {required String cle});
  Future<void> repondreContestation(
      String id, String mouvementId, Map<String, dynamic> corps);
}

class CautionRemoteDataSourceImpl implements CautionRemoteDataSource {
  final ApiClient api;
  CautionRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<CautionModel>> getCautions(
          {required int page, String? statut}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.cautions,
            query: {'page': page, 'status': statut, 'tri': '-created_at'}),
        CautionModel.fromJson,
      );

  @override
  Future<CautionModel> getCaution(String id) async =>
      CautionModel.fromJson(Map<String, dynamic>.from((await api
              .get<Map<String, dynamic>>(ApiEndpoints.caution(id)))['deposit']
          as Map));

  @override
  Future<void> verser(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.cautionVersements(id),
          body: corps, idempotence: cle);

  @override
  Future<void> restituer(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.cautionRestitutions(id),
          body: corps, idempotence: cle);

  @override
  Future<String> ajouterJustificatif(String id, String chemin) async {
    final r = await api.upload<Map<String, dynamic>>(
        ApiEndpoints.cautionJustificatifs(id),
        cheminFichier: chemin,
        idempotence: nouvelleCle());
    return '${(r['document'] as Map)['id']}';
  }

  @override
  Future<void> retenir(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.cautionRetenues(id),
          body: corps, idempotence: cle);

  @override
  Future<void> repondreContestation(
          String id, String mouvementId, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.cautionReponse(id, mouvementId),
          body: corps);
}
