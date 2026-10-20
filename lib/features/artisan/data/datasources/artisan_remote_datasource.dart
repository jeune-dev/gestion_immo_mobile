import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/artisan_model.dart';

abstract class ArtisanRemoteDataSource {
  Future<PageResultat<ArtisanModel>> getArtisans(
      {required int page, String? recherche, bool actifsSeulement = false});
  Future<ArtisanModel> getArtisan(String id);
  Future<ArtisanModel> creerArtisan(Map<String, dynamic> corps,
      {required String cle});
  Future<ArtisanModel> modifierArtisan(String id, Map<String, dynamic> corps);
  Future<void> definirActivite(String id, {required bool actif});
  Future<void> supprimerArtisan(String id);
}

class ArtisanRemoteDataSourceImpl implements ArtisanRemoteDataSource {
  final ApiClient api;
  ArtisanRemoteDataSourceImpl({required this.api});

  ArtisanModel _artisan(Map<String, dynamic> r) =>
      ArtisanModel.fromJson(Map<String, dynamic>.from(r['contractor'] as Map));

  @override
  Future<PageResultat<ArtisanModel>> getArtisans(
          {required int page,
          String? recherche,
          bool actifsSeulement = false}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(
          ApiEndpoints.artisans,
          query: {
            'page': page,
            'q': recherche,
            if (actifsSeulement) 'is_active': true,
            'tri': 'name'
          },
        ),
        ArtisanModel.fromJson,
      );

  @override
  Future<ArtisanModel> getArtisan(String id) async =>
      _artisan(await api.get<Map<String, dynamic>>(ApiEndpoints.artisan(id)));

  @override
  Future<ArtisanModel> creerArtisan(Map<String, dynamic> corps,
          {required String cle}) async =>
      _artisan(await api.post<Map<String, dynamic>>(ApiEndpoints.artisans,
          body: corps, idempotence: cle));

  @override
  Future<ArtisanModel> modifierArtisan(
          String id, Map<String, dynamic> corps) async =>
      _artisan(await api.patch<Map<String, dynamic>>(ApiEndpoints.artisan(id),
          body: corps));

  @override
  Future<void> definirActivite(String id, {required bool actif}) =>
      api.post<dynamic>(ApiEndpoints.artisanActivite(id, actif: actif));

  @override
  Future<void> supprimerArtisan(String id) =>
      api.delete<dynamic>(ApiEndpoints.artisan(id));
}
