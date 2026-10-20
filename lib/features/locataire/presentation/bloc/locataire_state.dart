import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/entities/locataire.dart';

abstract class LocataireState {}

class LocataireInitial extends LocataireState {}

class LocataireLoading extends LocataireState {}

class LocataireLoaded extends LocataireState {
  final Locataire locataire;
  LocataireLoaded(this.locataire);
}

/// Échec de la lecture de la fiche : l'écran affiche l'erreur et « Réessayer ».
/// La [Failure] est gardée entière pour distinguer réseau, abonnement…
class LocataireError extends LocataireState {
  final Failure failure;
  LocataireError(this.failure);

  String get message => failure.messageComplet;
}

/// Échec d'une action alors que la fiche est affichée : un simple message,
/// la fiche reste à l'écran.
class LocataireActionError extends LocataireState {
  final Failure failure;
  LocataireActionError(this.failure);

  String get message => failure.messageComplet;
}

class LocataireSuccess extends LocataireState {
  final String message;
  LocataireSuccess({this.message = 'Opération réussie'});
}

class LocataireInvitationLoaded extends LocataireState {
  final Invitation invitation;
  LocataireInvitationLoaded(this.invitation);
}

class LocataireSupprime extends LocataireState {
  final String message;
  LocataireSupprime({this.message = 'Locataire supprimé'});
}
