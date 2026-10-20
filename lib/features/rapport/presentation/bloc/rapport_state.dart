import 'package:gestion_immo_mobile/core/errors/failure.dart';

abstract class RapportState {}

class RapportInitial extends RapportState {}

class RapportLoading extends RapportState {}

class RapportLoaded<T> extends RapportState {
  final T rapport;
  RapportLoaded(this.rapport);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class RapportError extends RapportState {
  final Failure failure;
  String get message => failure.messageComplet;
  RapportError(this.failure);
}

/// Échec d'une relecture alors que le rapport est affiché : il reste à
/// l'écran.
class RapportActionError extends RapportState {
  final Failure failure;
  String get message => failure.messageComplet;
  RapportActionError(this.failure);
}
