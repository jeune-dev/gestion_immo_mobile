import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/bail_model.dart';

abstract class BailRemoteDataSource {
  Future<PageResultat<BailModel>> getBaux(
      {required int page, String? statut, String? recherche});
  Future<BailModel> getBail(String id);
  Future<List<ContratBailModel>> contrats(String id);
  Future<BailModel> creerBail(Map<String, dynamic> corps,
      {required String cle});
  Future<BailModel> modifierBail(String id, Map<String, dynamic> corps);

  /// Renvoie les avertissements de l'activation (état des lieux d'entrée absent…).
  Future<List<String>> activer(String id);
  Future<void> annulerBail(String id, String motif);
  Future<void> terminer(String id, Map<String, dynamic> corps);
  Future<void> cloturer(String id);
  Future<void> reviserLoyer(String id, Map<String, dynamic> corps);
  Future<void> genererContrat(String id, Map<String, dynamic> corps,
      {required String cle});
}

class BailRemoteDataSourceImpl implements BailRemoteDataSource {
  final ApiClient api;
  BailRemoteDataSourceImpl({required this.api});

  BailModel _bail(Map<String, dynamic> r) =>
      BailModel.fromJson(Map<String, dynamic>.from(r['lease'] as Map));

  @override
  Future<PageResultat<BailModel>> getBaux(
          {required int page, String? statut, String? recherche}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.baux, query: {
          'page': page,
          'status': statut,
          'q': recherche,
          'tri': '-start_date'
        }),
        BailModel.fromJson,
      );

  @override
  Future<BailModel> getBail(String id) async =>
      _bail(await api.get<Map<String, dynamic>>(ApiEndpoints.bail(id)));

  @override
  Future<List<ContratBailModel>> contrats(String id) async {
    final r =
        await api.get<Map<String, dynamic>>(ApiEndpoints.bailContrats(id));
    return ((r['contracts'] as List?) ?? const [])
        .map((c) =>
            ContratBailModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }

  @override
  Future<BailModel> creerBail(Map<String, dynamic> corps,
          {required String cle}) async =>
      _bail(await api.post<Map<String, dynamic>>(ApiEndpoints.baux,
          body: corps, idempotence: cle));

  @override
  Future<BailModel> modifierBail(String id, Map<String, dynamic> corps) async =>
      _bail(await api.patch<Map<String, dynamic>>(ApiEndpoints.bail(id),
          body: corps));

  @override
  Future<List<String>> activer(String id) async {
    final r = await api
        .post<Map<String, dynamic>>(ApiEndpoints.bailAction(id, 'activer'));
    return ((r['avertissements'] as List?) ?? const [])
        .map((a) => a is Map ? '${a['message']}' : '$a')
        .toList();
  }

  @override
  Future<void> annulerBail(String id, String motif) =>
      api.post<dynamic>(ApiEndpoints.bailAction(id, 'annuler'),
          body: {'reason': motif});

  @override
  Future<void> terminer(String id, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.bailAction(id, 'terminer'), body: corps);

  @override
  Future<void> cloturer(String id) =>
      api.post<dynamic>(ApiEndpoints.bailAction(id, 'cloturer'));

  @override
  Future<void> reviserLoyer(String id, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.bailAction(id, 'loyer'), body: corps);

  @override
  Future<void> genererContrat(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.bailContrats(id),
          body: corps, idempotence: cle);
}
