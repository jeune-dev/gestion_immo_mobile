import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/travaux.dart';
import '../repositories/travaux_repository.dart';

class CreerTravaux {
  final TravauxRepository repository;
  CreerTravaux(this.repository);

  Future<Either<Failure, Travaux>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.creerTravaux(corps, cle: cle);
}
