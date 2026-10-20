import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/abonnement.dart';
import '../models/abonnement_model.dart';

abstract class AbonnementRemoteDataSource {
  Future<FicheAbonnement> getFicheAbonnement();

  /// Renvoie l'URL de paiement PayDunya à ouvrir.
  Future<String?> souscrire(
      {required String planCode, required int mois, String? portefeuille});
}

class AbonnementRemoteDataSourceImpl implements AbonnementRemoteDataSource {
  final ApiClient api;
  AbonnementRemoteDataSourceImpl({required this.api});

  @override
  Future<FicheAbonnement> getFicheAbonnement() async {
    final (a, p, h) = await (
      api.get<Map<String, dynamic>>(ApiEndpoints.abonnement),
      api.get<Map<String, dynamic>>(ApiEndpoints.abonnementPlans),
      api.get<Map<String, dynamic>>(ApiEndpoints.abonnementPaiements,
          query: {'limit': 10}),
    ).wait;
    return FicheAbonnement(
      etat: AbonnementModel.etat(
          Map<String, dynamic>.from(a['abonnement'] as Map)),
      plans: listeJson(p['plans']).map(AbonnementModel.plan).toList(),
      paiements: listeJson(h['items']).map(AbonnementModel.paiement).toList(),
    );
  }

  @override
  Future<String?> souscrire(
      {required String planCode,
      required int mois,
      String? portefeuille}) async {
    final r = await api.post<Map<String, dynamic>>(
      ApiEndpoints.abonnementSouscrire,
      body: {
        'plan_code': planCode,
        'months': mois,
        if (portefeuille != null) 'wallet': portefeuille
      },
      idempotence: nouvelleCle(),
    );
    return r['checkout_url'] as String?;
  }
}
