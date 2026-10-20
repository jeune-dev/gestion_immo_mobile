import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/notifications_repository.dart';

class MarquerNotificationLue {
  final NotificationsRepository repository;
  MarquerNotificationLue(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.marquerLue(id);
}
