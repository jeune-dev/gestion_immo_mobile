abstract class PaiementEvent {}

class LoadPaiement extends PaiementEvent {
  final String id;
  LoadPaiement(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirPaiement extends PaiementEvent {
  final String id;
  RafraichirPaiement(this.id);
}

class ResetPaiementState extends PaiementEvent {}
