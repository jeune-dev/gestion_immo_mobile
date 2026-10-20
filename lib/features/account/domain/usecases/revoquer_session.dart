import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class RevoquerSession {
  final AccountRepository repository;
  RevoquerSession(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.revoquerSession(id);
}
