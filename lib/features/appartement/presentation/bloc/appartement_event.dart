abstract class AppartementEvent {}

class LoadAppartement extends AppartementEvent {
  final String id;
  LoadAppartement(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirAppartement extends AppartementEvent {
  final String id;
  RafraichirAppartement(this.id);
}

class ChangerStatutAppartementEvent extends AppartementEvent {
  final String id;
  final String statut;
  ChangerStatutAppartementEvent(this.id, this.statut);
}

class SupprimerAppartementEvent extends AppartementEvent {
  final String id;
  SupprimerAppartementEvent(this.id);
}

class ResetAppartementState extends AppartementEvent {}
