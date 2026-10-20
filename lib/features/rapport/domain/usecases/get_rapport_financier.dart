import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/rapports.dart';
import '../repositories/rapport_repository.dart';

class GetRapportFinancier {
  final RapportRepository repository;
  GetRapportFinancier(this.repository);

  Future<Either<Failure, RapportFinancier>> call(
          {required String du, required String au}) =>
      repository.financier(du: du, au: au);
}
