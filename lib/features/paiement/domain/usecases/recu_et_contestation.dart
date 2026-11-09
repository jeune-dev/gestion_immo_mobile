import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../repositories/paiement_repository.dart';

/// Reçu PDF d'un paiement, partiel compris.
class GetRecuPaiementProprietaire {
  final PaiementRepository repository;
  GetRecuPaiementProprietaire(this.repository);

  Future<Either<Failure, Uint8List>> call(String id) => repository.recu(id);
}

/// Réponse du propriétaire au locataire qui conteste un remboursement.
class RepondreContestationPaiement {
  final PaiementRepository repository;
  RepondreContestationPaiement(this.repository);

  Future<Either<Failure, void>> call(String id, String reponse) =>
      repository.repondreContestation(id, reponse);
}
