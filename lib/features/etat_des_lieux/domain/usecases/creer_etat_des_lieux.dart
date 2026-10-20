import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/etat_des_lieux.dart';
import '../repositories/etat_des_lieux_repository.dart';

class CreerEtatDesLieux {
  final EtatDesLieuxRepository repository;
  CreerEtatDesLieux(this.repository);

  Future<Either<Failure, EtatDesLieux>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.creerEtatDesLieux(corps, cle: cle);
}
