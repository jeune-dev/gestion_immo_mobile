import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';

abstract class EtatDesLieuxState {}

class EtatDesLieuxInitial extends EtatDesLieuxState {}

class EtatDesLieuxLoading extends EtatDesLieuxState {}

class EtatDesLieuxLoaded extends EtatDesLieuxState {
  final EtatDesLieux etatDesLieux;
  EtatDesLieuxLoaded(this.etatDesLieux);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class EtatDesLieuxError extends EtatDesLieuxState {
  final Failure failure;
  String get message => failure.messageComplet;
  EtatDesLieuxError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class EtatDesLieuxActionError extends EtatDesLieuxState {
  final Failure failure;
  String get message => failure.messageComplet;
  EtatDesLieuxActionError(this.failure);
}

class EtatDesLieuxSuccess extends EtatDesLieuxState {
  final String message;
  EtatDesLieuxSuccess({this.message = 'Opération réussie'});
}

/// Nouvelle version créée par une correction.
class NouvelleVersionLoaded extends EtatDesLieuxState {
  final EtatDesLieux version;
  NouvelleVersionLoaded(this.version);
}

class EtatDesLieuxSupprime extends EtatDesLieuxState {
  final String message;
  EtatDesLieuxSupprime({this.message = 'Brouillon supprimé'});
}
