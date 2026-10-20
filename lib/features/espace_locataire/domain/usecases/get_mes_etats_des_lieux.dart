import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMesEtatsDesLieux {
  final EspaceLocataireRepository repository;
  GetMesEtatsDesLieux(this.repository);

  Future<Either<Failure, PageResultat<EtatDesLieux>>> call(
          {required int page}) =>
      repository.etatsDesLieux(page: page);
}
