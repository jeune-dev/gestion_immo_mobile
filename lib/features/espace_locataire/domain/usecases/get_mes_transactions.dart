import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMesTransactions {
  final EspaceLocataireRepository repository;
  GetMesTransactions(this.repository);

  Future<Either<Failure, PageResultat<TransactionPaiement>>> call(
          {required int page}) =>
      repository.transactions(page: page);
}
