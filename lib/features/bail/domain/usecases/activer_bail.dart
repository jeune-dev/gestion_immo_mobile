import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/bail_repository.dart';

class ActiverBail {
  final BailRepository repository;
  ActiverBail(this.repository);

  Future<Either<Failure, List<String>>> call(String id) =>
      repository.activer(id);
}
