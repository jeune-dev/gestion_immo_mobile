import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class RevoquerAutresSessions {
  final AccountRepository repository;
  RevoquerAutresSessions(this.repository);

  Future<Either<Failure, void>> call() => repository.revoquerAutres();
}
