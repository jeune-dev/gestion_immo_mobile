import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/travaux.dart';
import '../repositories/travaux_repository.dart';

class GetTravaux {
  final TravauxRepository repository;
  GetTravaux(this.repository);

  Future<Either<Failure, Travaux>> call(String id) => repository.getTravaux(id);
}
