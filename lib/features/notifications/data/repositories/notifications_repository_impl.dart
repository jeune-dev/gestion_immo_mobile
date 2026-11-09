import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/notification_app.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;
  NotificationsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<NotificationApp>>> getNotifications({
    required int page,
    bool nonLues = false,
  }) => appelApi(
    () => remoteDataSource.getNotifications(page: page, nonLues: nonLues),
  );

  @override
  Future<Either<Failure, int>> compterNonLues() =>
      appelApi(() => remoteDataSource.compterNonLues());

  @override
  Future<Either<Failure, void>> marquerLue(String id) =>
      appelApi(() => remoteDataSource.marquerLue(id));

  @override
  Future<Either<Failure, void>> toutLire() =>
      appelApi(() => remoteDataSource.toutLire());
}
