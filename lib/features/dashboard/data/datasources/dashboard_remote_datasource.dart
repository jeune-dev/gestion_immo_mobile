import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../../domain/entities/tableau_de_bord.dart';
import '../models/tableau_de_bord_model.dart';

abstract class DashboardRemoteDataSource {
  Future<TableauDeBord> tableauDeBord();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient api;
  DashboardRemoteDataSourceImpl({required this.api});

  @override
  Future<TableauDeBord> tableauDeBord() async {
    final (d, g) = await (
      api.get<Map<String, dynamic>>(ApiEndpoints.dashboard),
      api.get<Map<String, dynamic>>(ApiEndpoints.dashboardGraphiques,
          query: {'nb_mois': 6}),
    ).wait;
    return TableauDeBordModel.depuis(
        Map<String, dynamic>.from(d['dashboard'] as Map),
        Map<String, dynamic>.from(g['graphiques'] as Map));
  }
}
