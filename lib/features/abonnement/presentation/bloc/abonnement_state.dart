import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/abonnement/domain/entities/abonnement.dart';

abstract class AbonnementState {}

class AbonnementInitial extends AbonnementState {}

class AbonnementLoading extends AbonnementState {}

class AbonnementLoaded extends AbonnementState {
  final FicheAbonnement fiche;
  AbonnementLoaded(this.fiche);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class AbonnementError extends AbonnementState {
  final Failure failure;
  String get message => failure.messageComplet;
  AbonnementError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class AbonnementActionError extends AbonnementState {
  final Failure failure;
  String get message => failure.messageComplet;
  AbonnementActionError(this.failure);
}

class AbonnementSuccess extends AbonnementState {
  final String message;
  AbonnementSuccess({this.message = 'Opération réussie'});
}

/// URL de paiement PayDunya renvoyée par la souscription.
class LienPaiementAbonnementLoaded extends AbonnementState {
  final String url;
  LienPaiementAbonnementLoaded(this.url);
}
