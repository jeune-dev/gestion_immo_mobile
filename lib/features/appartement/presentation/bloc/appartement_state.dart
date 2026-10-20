import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';

abstract class AppartementState {}

class AppartementInitial extends AppartementState {}

class AppartementLoading extends AppartementState {}

class AppartementLoaded extends AppartementState {
  final FicheAppartement fiche;
  AppartementLoaded(this.fiche);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class AppartementError extends AppartementState {
  final Failure failure;
  String get message => failure.messageComplet;
  AppartementError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class AppartementActionError extends AppartementState {
  final Failure failure;
  String get message => failure.messageComplet;
  AppartementActionError(this.failure);
}

class AppartementSuccess extends AppartementState {
  final String message;
  AppartementSuccess({this.message = 'Opération réussie'});
}

class AppartementSupprime extends AppartementState {
  final String message;
  AppartementSupprime({this.message = 'Appartement supprimé'});
}
