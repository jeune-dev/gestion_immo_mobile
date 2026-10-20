import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/parametres/domain/entities/parametres.dart';

abstract class ParametresState {}

class ParametresInitial extends ParametresState {}

class ParametresLoading extends ParametresState {}

class ParametresLoaded extends ParametresState {
  final ParametresProprietaire parametres;
  ParametresLoaded(this.parametres);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class ParametresError extends ParametresState {
  final Failure failure;
  String get message => failure.messageComplet;
  ParametresError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class ParametresActionError extends ParametresState {
  final Failure failure;
  String get message => failure.messageComplet;
  ParametresActionError(this.failure);
}

class ParametresSuccess extends ParametresState {
  final String message;
  ParametresSuccess({this.message = 'Opération réussie'});
}
