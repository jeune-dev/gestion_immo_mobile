import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/appartement.dart';
import '../repositories/appartement_repository.dart';

class GetFicheAppartement {
  final AppartementRepository repository;
  GetFicheAppartement(this.repository);

  Future<Either<Failure, FicheAppartement>> call(String id,
          {required int annee}) =>
      repository.getFicheAppartement(id, annee: annee);
}
