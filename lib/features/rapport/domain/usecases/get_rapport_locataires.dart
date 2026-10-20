import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/rapports.dart';
import '../repositories/rapport_repository.dart';

class GetRapportLocataires {
  final RapportRepository repository;
  GetRapportLocataires(this.repository);

  Future<Either<Failure, RapportLocataires>> call(
          {required String du, required String au}) =>
      repository.locataires(du: du, au: au);
}
