import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/etat_des_lieux.dart';
import '../repositories/etat_des_lieux_repository.dart';

class GetEtatsDesLieux {
  final EtatDesLieuxRepository repository;
  GetEtatsDesLieux(this.repository);

  Future<Either<Failure, PageResultat<EtatDesLieux>>> call(
          {required int page}) =>
      repository.getEtatsDesLieux(page: page);
}
