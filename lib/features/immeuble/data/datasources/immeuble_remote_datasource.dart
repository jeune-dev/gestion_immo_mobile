import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/immeuble_model.dart';

abstract class ImmeubleRemoteDataSource {
  Future<PageResultat<ImmeubleModel>> getImmeubles(
      {required int page, String? recherche});
  Future<ImmeubleModel> getImmeuble(String id);
  Future<ImmeubleModel> creerImmeuble(Map<String, dynamic> corps);
  Future<ImmeubleModel> modifierImmeuble(String id, Map<String, dynamic> corps);
  Future<void> supprimerImmeuble(String id);
}

class ImmeubleRemoteDataSourceImpl implements ImmeubleRemoteDataSource {
  final ApiClient api;
  ImmeubleRemoteDataSourceImpl({required this.api});

  ImmeubleModel _immeuble(Map<String, dynamic> r) =>
      ImmeubleModel.fromJson(Map<String, dynamic>.from(r['building'] as Map));

  @override
  Future<PageResultat<ImmeubleModel>> getImmeubles(
          {required int page, String? recherche}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.immeubles,
            query: {'page': page, 'q': recherche, 'tri': 'name'}),
        ImmeubleModel.fromJson,
      );

  @override
  Future<ImmeubleModel> getImmeuble(String id) async =>
      _immeuble(await api.get<Map<String, dynamic>>(ApiEndpoints.immeuble(id)));

  @override
  Future<ImmeubleModel> creerImmeuble(Map<String, dynamic> corps) async =>
      _immeuble(await api.post<Map<String, dynamic>>(ApiEndpoints.immeubles,
          body: corps));

  @override
  Future<ImmeubleModel> modifierImmeuble(
          String id, Map<String, dynamic> corps) async =>
      _immeuble(await api.patch<Map<String, dynamic>>(ApiEndpoints.immeuble(id),
          body: corps));

  @override
  Future<void> supprimerImmeuble(String id) =>
      api.delete<dynamic>(ApiEndpoints.immeuble(id));
}
