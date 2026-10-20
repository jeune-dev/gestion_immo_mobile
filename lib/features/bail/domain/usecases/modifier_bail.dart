import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/bail.dart';
import '../repositories/bail_repository.dart';

class ModifierBail {
  final BailRepository repository;
  ModifierBail(this.repository);

  Future<Either<Failure, Bail>> call(String id, Map<String, dynamic> corps) =>
      repository.modifierBail(id, corps);
}
