import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';

abstract class AccueilLocataireState {}

class AccueilLocataireInitial extends AccueilLocataireState {}

class AccueilLocataireLoading extends AccueilLocataireState {}

class AccueilLocataireLoaded extends AccueilLocataireState {
  final List<LogementLocataire> logements;
  AccueilLocataireLoaded(this.logements);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class AccueilLocataireError extends AccueilLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  AccueilLocataireError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class AccueilLocataireActionError extends AccueilLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  AccueilLocataireActionError(this.failure);
}
