import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetTransactions {
  final PaiementRepository repository;
  GetTransactions(this.repository);

  Future<Either<Failure, PageResultat<TransactionPaiement>>> call(
          {required int page, String? statut, bool preuvesSeulement = false}) =>
      repository.transactions(
          page: page, statut: statut, preuvesSeulement: preuvesSeulement);
}
