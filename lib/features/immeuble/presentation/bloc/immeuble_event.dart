abstract class ImmeubleEvent {}

class LoadImmeuble extends ImmeubleEvent {
  final String id;
  LoadImmeuble(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirImmeuble extends ImmeubleEvent {
  final String id;
  RafraichirImmeuble(this.id);
}

class SupprimerImmeubleEvent extends ImmeubleEvent {
  final String id;
  SupprimerImmeubleEvent(this.id);
}

class ResetImmeubleState extends ImmeubleEvent {}
