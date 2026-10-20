import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class RevoquerToutesSessions {
  final AccountRepository repository;
  RevoquerToutesSessions(this.repository);

  Future<Either<Failure, void>> call() => repository.revoquerToutes();
}
