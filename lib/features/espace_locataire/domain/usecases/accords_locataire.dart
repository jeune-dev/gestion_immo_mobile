import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../entities/accords.dart';
import '../repositories/espace_locataire_repository.dart';

/// Bail proposé et nouveau loyer en attente de la réponse du locataire.
class GetAccordsLocataire {
  final EspaceLocataireRepository repository;
  GetAccordsLocataire(this.repository);

  Future<Either<Failure, AccordsLocataire>> call() => repository.accords();
}

/// Démarche du locataire : accepter ou refuser un bail ou un nouveau loyer,
/// donner congé, déclarer des espèces, contester un remboursement.
class ActionLocataire {
  final EspaceLocataireRepository repository;
  ActionLocataire(this.repository);

  Future<Either<Failure, void>> call(
    String chemin, {
    Map<String, dynamic> corps = const {},
  }) => repository.action(chemin, corps: corps);
}

/// Reçu PDF d'un paiement.
class GetRecuPaiement {
  final EspaceLocataireRepository repository;
  GetRecuPaiement(this.repository);

  Future<Either<Failure, Uint8List>> call(String id) =>
      repository.recuPaiement(id);
}
