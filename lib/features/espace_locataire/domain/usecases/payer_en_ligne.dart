import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/espace_locataire.dart';
import '../repositories/espace_locataire_repository.dart';

class PayerEnLigne {
  final EspaceLocataireRepository repository;
  PayerEnLigne(this.repository);

  /// Jamais hors ligne : toute confirmation vient du serveur.
  Future<Either<Failure, DemandePaiement>> call(
          {String? echeanceId,
          String? chargeId,
          required String portefeuille,
          int? montant}) =>
      repository.payer(
          echeanceId: echeanceId,
          chargeId: chargeId,
          portefeuille: portefeuille,
          montant: montant);
}
