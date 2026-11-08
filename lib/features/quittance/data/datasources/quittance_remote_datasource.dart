import 'dart:typed_data';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';

import '../models/quittance_model.dart';

/// Quittances du propriétaire (`/quittances`) ou du locataire (`/locataire/quittances`).
abstract class QuittanceRemoteDataSource {
  Future<PageResultat<QuittanceModel>> getQuittances({
    required int page,
    required bool espaceLocataire,
  });

  Future<QuittanceModel> getQuittance(
    String id, {
    required bool espaceLocataire,
  });

  /// 503 QUITTANCE_EN_PREPARATION juste après un paiement : le client réessaie.
  Future<Uint8List> pdf(String id, {required bool espaceLocataire});
}

class QuittanceRemoteDataSourceImpl implements QuittanceRemoteDataSource {
  final ApiClient api;
  QuittanceRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<QuittanceModel>> getQuittances({
    required int page,
    required bool espaceLocataire,
  }) async => PageResultat.depuisJson(
    await api.get<Map<String, dynamic>>(
      espaceLocataire ? ApiEndpoints.locQuittances : ApiEndpoints.quittances,
      query: {'page': page, 'tri': '-issued_at'},
    ),
    QuittanceModel.fromJson,
  );

  @override
  Future<QuittanceModel> getQuittance(
    String id, {
    required bool espaceLocataire,
  }) async {
    final r = await api.get<Map<String, dynamic>>(
      espaceLocataire
          ? ApiEndpoints.locQuittance(id)
          : ApiEndpoints.quittance(id),
    );
    return QuittanceModel.fromJson(
      Map<String, dynamic>.from(r['receipt'] as Map),
    );
  }

  @override
  Future<Uint8List> pdf(String id, {required bool espaceLocataire}) =>
      api.telecharger(
        espaceLocataire
            ? ApiEndpoints.locQuittancePdf(id)
            : ApiEndpoints.quittancePdf(id),
      );
}
