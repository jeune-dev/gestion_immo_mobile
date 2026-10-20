import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/rapports.dart';
import '../repositories/rapport_repository.dart';

class GetRentabilite {
  final RapportRepository repository;
  GetRentabilite(this.repository);

  Future<Either<Failure, PageResultat<LigneRentabilite>>> call(
          {required int page, required String du, required String au}) =>
      repository.rentabilite(page: page, du: du, au: au);
}
