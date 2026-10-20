import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/notifications_repository.dart';

class ToutLire {
  final NotificationsRepository repository;
  ToutLire(this.repository);

  Future<Either<Failure, void>> call() => repository.toutLire();
}
