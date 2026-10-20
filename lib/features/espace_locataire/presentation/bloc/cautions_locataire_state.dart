import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';

abstract class CautionsLocataireState {}

class CautionsLocataireInitial extends CautionsLocataireState {}

class CautionsLocataireLoading extends CautionsLocataireState {}

class CautionsLocataireLoaded extends CautionsLocataireState {
  final List<Caution> cautions;
  CautionsLocataireLoaded(this.cautions);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class CautionsLocataireError extends CautionsLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  CautionsLocataireError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class CautionsLocataireActionError extends CautionsLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  CautionsLocataireActionError(this.failure);
}

class CautionsLocataireSuccess extends CautionsLocataireState {
  final String message;
  CautionsLocataireSuccess({this.message = 'Opération réussie'});
}
