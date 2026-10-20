abstract class ComparaisonEvent {}

class LoadComparaison extends ComparaisonEvent {
  final String bailId;
  LoadComparaison(this.bailId);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirComparaison extends ComparaisonEvent {
  final String bailId;
  RafraichirComparaison(this.bailId);
}

class ResetComparaisonState extends ComparaisonEvent {}
