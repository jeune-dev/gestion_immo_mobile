import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/appartement.dart';
import '../repositories/appartement_repository.dart';

class CreerAppartement {
  final AppartementRepository repository;
  CreerAppartement(this.repository);

  Future<Either<Failure, Appartement>> call(Map<String, dynamic> corps) =>
      repository.creerAppartement(corps);
}
