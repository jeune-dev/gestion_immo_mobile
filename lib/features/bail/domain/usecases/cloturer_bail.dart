import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/bail_repository.dart';

class CloturerBail {
  final BailRepository repository;
  CloturerBail(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.cloturer(id);
}
