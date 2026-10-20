import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final TransactionPaiement transaction;
  TransactionLoaded(this.transaction);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class TransactionError extends TransactionState {
  final Failure failure;
  String get message => failure.messageComplet;
  TransactionError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class TransactionActionError extends TransactionState {
  final Failure failure;
  String get message => failure.messageComplet;
  TransactionActionError(this.failure);
}

class TransactionSuccess extends TransactionState {
  final String message;
  TransactionSuccess({this.message = 'Opération réussie'});
}
