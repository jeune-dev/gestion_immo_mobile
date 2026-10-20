import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/session_appareil.dart';
import '../repositories/account_repository.dart';

class GetSessions {
  final AccountRepository repository;
  GetSessions(this.repository);

  Future<Either<Failure, List<SessionAppareil>>> call() =>
      repository.sessions();
}
