import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';

abstract class IncidentLocataireState {}

class IncidentLocataireInitial extends IncidentLocataireState {}

class IncidentLocataireLoading extends IncidentLocataireState {}

class IncidentLocataireLoaded extends IncidentLocataireState {
  final Incident incident;
  IncidentLocataireLoaded(this.incident);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class IncidentLocataireError extends IncidentLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  IncidentLocataireError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class IncidentLocataireActionError extends IncidentLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  IncidentLocataireActionError(this.failure);
}

class IncidentLocataireSuccess extends IncidentLocataireState {
  final String message;
  IncidentLocataireSuccess({this.message = 'Opération réussie'});
}
