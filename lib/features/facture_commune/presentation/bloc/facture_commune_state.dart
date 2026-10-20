import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';

abstract class FactureCommuneState {}

class FactureCommuneInitial extends FactureCommuneState {}

class FactureCommuneLoading extends FactureCommuneState {}

class FactureCommuneLoaded extends FactureCommuneState {
  final FactureCommune facture;
  FactureCommuneLoaded(this.facture);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class FactureCommuneError extends FactureCommuneState {
  final Failure failure;
  String get message => failure.messageComplet;
  FactureCommuneError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class FactureCommuneActionError extends FactureCommuneState {
  final Failure failure;
  String get message => failure.messageComplet;
  FactureCommuneActionError(this.failure);
}

class FactureCommuneSuccess extends FactureCommuneState {
  final String message;
  FactureCommuneSuccess({this.message = 'Opération réussie'});
}
