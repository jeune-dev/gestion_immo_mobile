import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';

abstract class MoyensPaiementState {}

class MoyensPaiementInitial extends MoyensPaiementState {}

class MoyensPaiementLoading extends MoyensPaiementState {}

class MoyensPaiementLoaded extends MoyensPaiementState {
  final List<MoyenPaiement> moyens;
  MoyensPaiementLoaded(this.moyens);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class MoyensPaiementError extends MoyensPaiementState {
  final Failure failure;
  String get message => failure.messageComplet;
  MoyensPaiementError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class MoyensPaiementActionError extends MoyensPaiementState {
  final Failure failure;
  String get message => failure.messageComplet;
  MoyensPaiementActionError(this.failure);
}
