import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';

abstract class PaiementLocataireState {}

class PaiementLocataireInitial extends PaiementLocataireState {}

class PaiementLocataireLoading extends PaiementLocataireState {}

class PaiementLocataireLoaded extends PaiementLocataireState {
  final MoyensPaiementLocataire moyens;
  PaiementLocataireLoaded(this.moyens);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class PaiementLocataireError extends PaiementLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  PaiementLocataireError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class PaiementLocataireActionError extends PaiementLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  PaiementLocataireActionError(this.failure);
}

class PaiementLocataireSuccess extends PaiementLocataireState {
  final String message;
  PaiementLocataireSuccess({this.message = 'Opération réussie'});
}

class DemandePaiementLoaded extends PaiementLocataireState {
  final DemandePaiement demande;
  DemandePaiementLoaded(this.demande);
}
