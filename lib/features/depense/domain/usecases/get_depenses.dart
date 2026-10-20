import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/depense.dart';
import '../repositories/depense_repository.dart';

class GetDepenses {
  final DepenseRepository repository;
  GetDepenses(this.repository);

  Future<Either<Failure, PageResultat<Depense>>> call(
          {required int page, String? statut}) =>
      repository.getDepenses(page: page, statut: statut);
}
