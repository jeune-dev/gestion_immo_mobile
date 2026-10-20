import 'dart:typed_data';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../../domain/entities/rapports.dart';
import '../models/rapports_model.dart';

abstract class RapportRemoteDataSource {
  /// Rapport brut (`financier`, `immobilier`, `locataires`, `travaux`).
  Future<Map<String, dynamic>> rapport(String type,
      {required String du, required String au});
  Future<PageResultat<LigneRentabilite>> rentabilite(
      {required int page, required String du, required String au});
  Future<Uint8List> exporterCsv(String type,
      {required String du, required String au});
}

class RapportRemoteDataSourceImpl implements RapportRemoteDataSource {
  final ApiClient api;
  RapportRemoteDataSourceImpl({required this.api});

  @override
  Future<Map<String, dynamic>> rapport(String type,
      {required String du, required String au}) async {
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.rapport(type),
        query: {'du': du, 'au': au});
    return Map<String, dynamic>.from(r['rapport'] as Map);
  }

  @override
  Future<PageResultat<LigneRentabilite>> rentabilite(
          {required int page, required String du, required String au}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.rapport('rentabilite'),
            query: {'du': du, 'au': au, 'page': page, 'tri': '-resultat_net'}),
        RapportsModel.rentabilite,
      );

  @override
  Future<Uint8List> exporterCsv(String type,
          {required String du, required String au}) =>
      api.telecharger(ApiEndpoints.rapport(type),
          query: {'du': du, 'au': au, 'format': 'csv'});
}
