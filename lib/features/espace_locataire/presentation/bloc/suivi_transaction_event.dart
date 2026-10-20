abstract class SuiviTransactionEvent {}

/// Première vérification, puis toutes les 5 s pendant 5 minutes.
class DemarrerSuiviTransaction extends SuiviTransactionEvent {
  final String id;
  DemarrerSuiviTransaction(this.id);
}

/// Vérification à la demande (bouton, retour dans l'application).
class VerifierTransactionEvent extends SuiviTransactionEvent {
  final String id;
  VerifierTransactionEvent(this.id);
}
