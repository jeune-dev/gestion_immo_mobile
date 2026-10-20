import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/notifications_repository.dart';

class CompterNotificationsNonLues {
  final NotificationsRepository repository;
  CompterNotificationsNonLues(this.repository);

  Future<Either<Failure, int>> call() => repository.compterNonLues();
}
