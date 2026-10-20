import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';

abstract class ComparaisonState {}

class ComparaisonInitial extends ComparaisonState {}

class ComparaisonLoading extends ComparaisonState {}

class ComparaisonLoaded extends ComparaisonState {
  final ComparaisonEdl comparaison;
  ComparaisonLoaded(this.comparaison);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class ComparaisonError extends ComparaisonState {
  final Failure failure;
  String get message => failure.messageComplet;
  ComparaisonError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class ComparaisonActionError extends ComparaisonState {
  final Failure failure;
  String get message => failure.messageComplet;
  ComparaisonActionError(this.failure);
}
