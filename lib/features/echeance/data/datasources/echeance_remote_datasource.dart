import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';

import '../models/echeance_detail_model.dart';
import '../models/echeance_model.dart';

abstract class EcheanceRemoteDataSource {
  Future<PageResultat<EcheanceModel>> getEcheances({
    required int page,
    String? bailId,
    String? locataireId,
    bool impayes = false,
    String? statut,
  });

  /// Fiche d'une échéance : celle du propriétaire, ou celle du locataire
  /// connecté avec [espaceLocataire].
  Future<EcheanceDetailModel> getEcheance(
    String id, {
    bool espaceLocataire = false,
  });
  Future<void> annulerEcheance(String id, String motif);
}

class EcheanceRemoteDataSourceImpl implements EcheanceRemoteDataSource {
  final ApiClient api;
  EcheanceRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<EcheanceModel>> getEcheances({
    required int page,
    String? bailId,
    String? locataireId,
    bool impayes = false,
    String? statut,
  }) async => PageResultat.depuisJson(
    await api.get<Map<String, dynamic>>(
      ApiEndpoints.echeances,
      query: {
        'page': page,
        'lease_id': bailId,
        'tenant_id': locataireId,
        if (impayes) 'impayes': true else 'status': statut,
        // Impayés : les plus anciens d'abord
        'tri': impayes ? 'due_date' : '-due_date',
      },
    ),
    EcheanceModel.fromJson,
  );

  @override
  Future<EcheanceDetailModel> getEcheance(
    String id, {
    bool espaceLocataire = false,
  }) async {
    final r = await api.get<Map<String, dynamic>>(
      espaceLocataire
          ? ApiEndpoints.locEcheance(id)
          : ApiEndpoints.echeance(id),
    );
    return EcheanceDetailModel.fromJson(
      Map<String, dynamic>.from(r['schedule'] as Map),
    );
  }

  @override
  Future<void> annulerEcheance(String id, String motif) => api.post<dynamic>(
    ApiEndpoints.echeanceAnnuler(id),
    body: {'reason': motif},
  );
}
