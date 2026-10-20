import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class ActiverMfa {
  final AccountRepository repository;
  ActiverMfa(this.repository);

  Future<Either<Failure, List<String>>> call(String code) =>
      repository.activerMfa(code);
}
