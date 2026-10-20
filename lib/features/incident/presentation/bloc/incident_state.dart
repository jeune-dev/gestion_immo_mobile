import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';

abstract class IncidentState {}

class IncidentInitial extends IncidentState {}

class IncidentLoading extends IncidentState {}

class IncidentLoaded extends IncidentState {
  final Incident incident;
  IncidentLoaded(this.incident);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class IncidentError extends IncidentState {
  final Failure failure;
  String get message => failure.messageComplet;
  IncidentError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class IncidentActionError extends IncidentState {
  final Failure failure;
  String get message => failure.messageComplet;
  IncidentActionError(this.failure);
}

class IncidentSuccess extends IncidentState {
  final String message;
  IncidentSuccess({this.message = 'Opération réussie'});
}
