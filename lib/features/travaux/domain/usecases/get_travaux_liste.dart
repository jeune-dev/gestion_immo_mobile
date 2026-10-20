import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/travaux.dart';
import '../repositories/travaux_repository.dart';

class GetTravauxListe {
  final TravauxRepository repository;
  GetTravauxListe(this.repository);

  Future<Either<Failure, PageResultat<Travaux>>> call(
          {required int page, String? statut}) =>
      repository.getListeTravaux(page: page, statut: statut);
}
