import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/bail_repository.dart';

class ReviserLoyer {
  final BailRepository repository;
  ReviserLoyer(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps) =>
      repository.reviserLoyer(id, corps);
}
