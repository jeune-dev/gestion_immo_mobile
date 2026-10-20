import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/appartement.dart';
import '../repositories/appartement_repository.dart';

class GetAppartements {
  final AppartementRepository repository;
  GetAppartements(this.repository);

  Future<Either<Failure, PageResultat<Appartement>>> call(
          {required int page,
          String? recherche,
          String? statut,
          String? immeubleId,
          int? limite}) =>
      repository.getAppartements(
          page: page,
          recherche: recherche,
          statut: statut,
          immeubleId: immeubleId,
          limite: limite);
}
