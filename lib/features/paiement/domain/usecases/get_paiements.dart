import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetPaiements {
  final PaiementRepository repository;
  GetPaiements(this.repository);

  Future<Either<Failure, PageResultat<Paiement>>> call(
          {required int page, String? moyen}) =>
      repository.getPaiements(page: page, moyen: moyen);
}
