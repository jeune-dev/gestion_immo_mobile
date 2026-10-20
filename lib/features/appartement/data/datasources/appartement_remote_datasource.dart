import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/appartement_model.dart';

abstract class AppartementRemoteDataSource {
  Future<PageResultat<AppartementModel>> getAppartements(
      {required int page,
      String? recherche,
      String? statut,
      String? immeubleId,
      int? limite});
  Future<AppartementModel> getAppartement(String id);
  Future<RentabiliteAppartementModel> rentabilite(String id,
      {required String du, required String au});
  Future<List<EvenementAppartementModel>> historique(String id);
  Future<AppartementModel> creerAppartement(Map<String, dynamic> corps);
  Future<AppartementModel> modifierAppartement(
      String id, Map<String, dynamic> corps);
  Future<void> changerStatutAppartement(String id, String statut);
  Future<void> supprimerAppartement(String id);
}

class AppartementRemoteDataSourceImpl implements AppartementRemoteDataSource {
  final ApiClient api;
  AppartementRemoteDataSourceImpl({required this.api});

  AppartementModel _appartement(Map<String, dynamic> r) =>
      AppartementModel.fromJson(
          Map<String, dynamic>.from(r['apartment'] as Map));

  @override
  Future<PageResultat<AppartementModel>> getAppartements(
          {required int page,
          String? recherche,
          String? statut,
          String? immeubleId,
          int? limite}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(
          ApiEndpoints.appartements,
          query: {
            'page': page,
            'limit': limite,
            'q': recherche,
            'status': statut,
            'building_id': immeubleId,
            'tri': 'number'
          },
        ),
        AppartementModel.fromJson,
      );

  @override
  Future<AppartementModel> getAppartement(String id) async => _appartement(
      await api.get<Map<String, dynamic>>(ApiEndpoints.appartement(id)));

  @override
  Future<RentabiliteAppartementModel> rentabilite(String id,
      {required String du, required String au}) async {
    final r = await api.get<Map<String, dynamic>>(
        ApiEndpoints.appartementRentabilite(id),
        query: {'du': du, 'au': au});
    return RentabiliteAppartementModel.fromJson(
        Map<String, dynamic>.from(r['rentabilite'] as Map));
  }

  @override
  Future<List<EvenementAppartementModel>> historique(String id) async {
    final r = await api.get<Map<String, dynamic>>(
        ApiEndpoints.appartementHistorique(id),
        query: {'limit': 15});
    return PageResultat.depuisJson(r, EvenementAppartementModel.fromJson).items;
  }

  @override
  Future<AppartementModel> creerAppartement(Map<String, dynamic> corps) async =>
      _appartement(await api
          .post<Map<String, dynamic>>(ApiEndpoints.appartements, body: corps));

  @override
  Future<AppartementModel> modifierAppartement(
          String id, Map<String, dynamic> corps) async =>
      _appartement(await api.patch<Map<String, dynamic>>(
          ApiEndpoints.appartement(id),
          body: corps));

  @override
  Future<void> changerStatutAppartement(String id, String statut) =>
      api.patch<dynamic>(ApiEndpoints.appartementStatut(id),
          body: {'status': statut});

  @override
  Future<void> supprimerAppartement(String id) =>
      api.delete<dynamic>(ApiEndpoints.appartement(id));
}
