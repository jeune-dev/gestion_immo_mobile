import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/caution.dart';
import '../repositories/caution_repository.dart';

class GetCaution {
  final CautionRepository repository;
  GetCaution(this.repository);

  Future<Either<Failure, Caution>> call(String id) => repository.getCaution(id);
}
