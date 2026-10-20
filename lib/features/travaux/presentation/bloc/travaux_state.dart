import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/entities/travaux.dart';

abstract class TravauxState {}

class TravauxInitial extends TravauxState {}

class TravauxLoading extends TravauxState {}

class TravauxLoaded extends TravauxState {
  final Travaux travaux;
  TravauxLoaded(this.travaux);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class TravauxError extends TravauxState {
  final Failure failure;
  String get message => failure.messageComplet;
  TravauxError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class TravauxActionError extends TravauxState {
  final Failure failure;
  String get message => failure.messageComplet;
  TravauxActionError(this.failure);
}

class TravauxSuccess extends TravauxState {
  final String message;
  TravauxSuccess({this.message = 'Opération réussie'});
}
