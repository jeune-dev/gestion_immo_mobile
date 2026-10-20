import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';

abstract class PaiementState {}

class PaiementInitial extends PaiementState {}

class PaiementLoading extends PaiementState {}

class PaiementLoaded extends PaiementState {
  final FichePaiement fiche;
  PaiementLoaded(this.fiche);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class PaiementError extends PaiementState {
  final Failure failure;
  String get message => failure.messageComplet;
  PaiementError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class PaiementActionError extends PaiementState {
  final Failure failure;
  String get message => failure.messageComplet;
  PaiementActionError(this.failure);
}
