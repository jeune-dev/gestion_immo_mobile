import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<PageResultat<NotificationModel>> getNotifications(
      {required int page, bool nonLues = false});
  Future<int> compterNonLues();
  Future<void> marquerLue(String id);
  Future<void> toutLire();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiClient api;
  NotificationsRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<NotificationModel>> getNotifications(
          {required int page, bool nonLues = false}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.notifications,
            query: {'page': page, if (nonLues) 'non_lues': true}),
        NotificationModel.fromJson,
      );

  @override
  Future<int> compterNonLues() async => entier(
      (await api.get<Map<String, dynamic>>(ApiEndpoints.notificationsCompteur,
          cache: false))['non_lues']);

  @override
  Future<void> marquerLue(String id) =>
      api.post<dynamic>(ApiEndpoints.notificationLue(id));

  @override
  Future<void> toutLire() =>
      api.post<dynamic>(ApiEndpoints.notificationsToutLire);
}
