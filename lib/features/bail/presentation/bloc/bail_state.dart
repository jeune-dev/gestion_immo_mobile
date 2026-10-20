import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';

abstract class BailState {}

class BailInitial extends BailState {}

class BailLoading extends BailState {}

class BailLoaded extends BailState {
  final FicheBail fiche;
  BailLoaded(this.fiche);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class BailError extends BailState {
  final Failure failure;
  String get message => failure.messageComplet;
  BailError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class BailActionError extends BailState {
  final Failure failure;
  String get message => failure.messageComplet;
  BailActionError(this.failure);
}

class BailSuccess extends BailState {
  final String message;
  BailSuccess({this.message = 'Opération réussie'});
}

/// Avertissements renvoyés par l'activation (état des lieux d'entrée
/// absent…).
class AvertissementsActivationLoaded extends BailState {
  final List<String> messages;
  AvertissementsActivationLoaded(this.messages);
}
