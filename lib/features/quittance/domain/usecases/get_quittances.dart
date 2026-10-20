import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/quittance.dart';
import '../repositories/quittance_repository.dart';

class GetQuittances {
  final QuittanceRepository repository;
  GetQuittances(this.repository);

  Future<Either<Failure, PageResultat<Quittance>>> call(
          {required int page, bool espaceLocataire = false}) =>
      repository.getQuittances(page: page, espaceLocataire: espaceLocataire);
}
