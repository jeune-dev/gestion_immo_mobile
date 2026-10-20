import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMonEtatDesLieux {
  final EspaceLocataireRepository repository;
  GetMonEtatDesLieux(this.repository);

  Future<Either<Failure, EtatDesLieux>> call(String id) =>
      repository.etatDesLieux(id);
}
