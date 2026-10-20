import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/caisse_model.dart';

abstract class CaisseRemoteDataSource {
  Future<PageResultat<MouvementCaisseModel>> mouvements(
      {required int page, required String du, required String au});
  Future<SyntheseCaisseModel> synthese(
      {required String du, required String au});
  Future<void> ajouterAutreRevenu(Map<String, dynamic> corps,
      {required String cle});
  Future<void> annulerOperationCaisse(String id, String motif);
}

class CaisseRemoteDataSourceImpl implements CaisseRemoteDataSource {
  final ApiClient api;
  CaisseRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<MouvementCaisseModel>> mouvements(
          {required int page, required String du, required String au}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.caisse,
            query: {'page': page, 'du': du, 'au': au}),
        MouvementCaisseModel.fromJson,
      );

  @override
  Future<SyntheseCaisseModel> synthese(
      {required String du, required String au}) async {
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.caisseSynthese,
        query: {'du': du, 'au': au});
    return SyntheseCaisseModel.fromJson(
        Map<String, dynamic>.from(r['caisse'] as Map));
  }

  @override
  Future<void> ajouterAutreRevenu(Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.caisseAutresRevenus,
          body: corps, idempotence: cle);

  @override
  Future<void> annulerOperationCaisse(String id, String motif) => api
      .post<dynamic>(ApiEndpoints.caisseAnnuler(id), body: {'reason': motif});
}
