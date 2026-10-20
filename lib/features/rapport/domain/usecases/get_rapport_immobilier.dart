import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/rapports.dart';
import '../repositories/rapport_repository.dart';

class GetRapportImmobilier {
  final RapportRepository repository;
  GetRapportImmobilier(this.repository);

  Future<Either<Failure, RapportImmobilier>> call(
          {required String du, required String au}) =>
      repository.immobilier(du: du, au: au);
}
