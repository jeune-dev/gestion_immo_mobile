import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetRapprochements {
  final PaiementRepository repository;
  GetRapprochements(this.repository);

  Future<Either<Failure, PageResultat<Rapprochement>>> call(
          {required int page, String? statut}) =>
      repository.rapprochements(page: page, statut: statut);
}
