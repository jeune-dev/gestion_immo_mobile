import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';

abstract class SuiviTransactionState {}

class SuiviTransactionInitial extends SuiviTransactionState {}

class SuiviTransactionLoaded extends SuiviTransactionState {
  final TransactionPaiement transaction;
  SuiviTransactionLoaded(this.transaction);
}
