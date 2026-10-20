import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/bail_repository.dart';

class TerminerBail {
  final BailRepository repository;
  TerminerBail(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps) =>
      repository.terminer(id, corps);
}
