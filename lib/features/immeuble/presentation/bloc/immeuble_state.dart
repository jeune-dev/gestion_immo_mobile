import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/entities/immeuble.dart';

/// Fiche d'un immeuble : l'immeuble et ses appartements.
typedef FicheImmeuble = ({Immeuble immeuble, List<Appartement> appartements});

abstract class ImmeubleState {}

class ImmeubleInitial extends ImmeubleState {}

class ImmeubleLoading extends ImmeubleState {}

class ImmeubleLoaded extends ImmeubleState {
  final FicheImmeuble fiche;
  ImmeubleLoaded(this.fiche);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class ImmeubleError extends ImmeubleState {
  final Failure failure;
  String get message => failure.messageComplet;
  ImmeubleError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class ImmeubleActionError extends ImmeubleState {
  final Failure failure;
  String get message => failure.messageComplet;
  ImmeubleActionError(this.failure);
}

class ImmeubleSuccess extends ImmeubleState {
  final String message;
  ImmeubleSuccess({this.message = 'Opération réussie'});
}

class ImmeubleSupprime extends ImmeubleState {
  final String message;
  ImmeubleSupprime({this.message = 'Immeuble supprimé'});
}
