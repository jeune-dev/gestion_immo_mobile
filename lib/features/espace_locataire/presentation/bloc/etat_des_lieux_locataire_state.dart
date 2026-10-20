import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';

abstract class EtatDesLieuxLocataireState {}

class EtatDesLieuxLocataireInitial extends EtatDesLieuxLocataireState {}

class EtatDesLieuxLocataireLoading extends EtatDesLieuxLocataireState {}

class EtatDesLieuxLocataireLoaded extends EtatDesLieuxLocataireState {
  final EtatDesLieux etatDesLieux;
  EtatDesLieuxLocataireLoaded(this.etatDesLieux);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class EtatDesLieuxLocataireError extends EtatDesLieuxLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  EtatDesLieuxLocataireError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class EtatDesLieuxLocataireActionError extends EtatDesLieuxLocataireState {
  final Failure failure;
  String get message => failure.messageComplet;
  EtatDesLieuxLocataireActionError(this.failure);
}

class EtatDesLieuxLocataireSuccess extends EtatDesLieuxLocataireState {
  final String message;
  EtatDesLieuxLocataireSuccess({this.message = 'Opération réussie'});
}
