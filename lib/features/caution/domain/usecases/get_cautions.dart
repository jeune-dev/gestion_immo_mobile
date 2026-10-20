import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/caution.dart';
import '../repositories/caution_repository.dart';

class GetCautions {
  final CautionRepository repository;
  GetCautions(this.repository);

  Future<Either<Failure, PageResultat<Caution>>> call(
          {required int page, String? statut}) =>
      repository.getCautions(page: page, statut: statut);
}
