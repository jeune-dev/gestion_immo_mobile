import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/rapports.dart';
import '../repositories/rapport_repository.dart';

class GetRapportTravaux {
  final RapportRepository repository;
  GetRapportTravaux(this.repository);

  Future<Either<Failure, RapportTravaux>> call(
          {required String du, required String au}) =>
      repository.travaux(du: du, au: au);
}
