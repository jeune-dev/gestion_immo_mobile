import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../../domain/entities/parametres.dart';
import '../models/parametres_model.dart';

abstract class ParametresRemoteDataSource {
  Future<ParametresProprietaire> lire();
  Future<void> modifierReglages(Map<String, dynamic> corps);
  Future<void> modifierEspace(Map<String, dynamic> corps);
}

class ParametresRemoteDataSourceImpl implements ParametresRemoteDataSource {
  final ApiClient api;
  ParametresRemoteDataSourceImpl({required this.api});

  @override
  Future<ParametresProprietaire> lire() async =>
      ParametresModel.depuis(await api
          .get<Map<String, dynamic>>(ApiEndpoints.parametres, cache: false));

  @override
  Future<void> modifierReglages(Map<String, dynamic> corps) =>
      api.patch<dynamic>(ApiEndpoints.parametres, body: corps);

  @override
  Future<void> modifierEspace(Map<String, dynamic> corps) =>
      api.patch<dynamic>(ApiEndpoints.parametresProfil, body: corps);
}
