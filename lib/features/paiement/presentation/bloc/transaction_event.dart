abstract class TransactionEvent {}

class LoadTransaction extends TransactionEvent {
  final String id;
  LoadTransaction(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirTransaction extends TransactionEvent {
  final String id;
  RafraichirTransaction(this.id);
}

class ValiderTransactionEvent extends TransactionEvent {
  final String id;
  ValiderTransactionEvent(this.id);
}

class RejeterTransactionEvent extends TransactionEvent {
  final String id;
  final String motif;
  RejeterTransactionEvent(this.id, this.motif);
}

class ResetTransactionState extends TransactionEvent {}
