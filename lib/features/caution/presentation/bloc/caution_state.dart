import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';

abstract class CautionState {}

class CautionInitial extends CautionState {}

class CautionLoading extends CautionState {}

class CautionLoaded extends CautionState {
  final Caution caution;
  CautionLoaded(this.caution);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class CautionError extends CautionState {
  final Failure failure;
  String get message => failure.messageComplet;
  CautionError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class CautionActionError extends CautionState {
  final Failure failure;
  String get message => failure.messageComplet;
  CautionActionError(this.failure);
}
