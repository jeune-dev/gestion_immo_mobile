import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/notification_app.dart';
import '../repositories/notifications_repository.dart';

class GetNotifications {
  final NotificationsRepository repository;
  GetNotifications(this.repository);

  Future<Either<Failure, PageResultat<NotificationApp>>> call(
          {required int page, bool nonLues = false}) =>
      repository.getNotifications(page: page, nonLues: nonLues);
}
