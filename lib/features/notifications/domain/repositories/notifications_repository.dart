import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/notification_app.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, PageResultat<NotificationApp>>> getNotifications(
      {required int page, bool nonLues = false});
  Future<Either<Failure, int>> compterNonLues();
  Future<Either<Failure, void>> marquerLue(String id);
  Future<Either<Failure, void>> toutLire();
}
