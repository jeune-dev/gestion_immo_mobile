abstract class CautionEvent {}

class LoadCaution extends CautionEvent {
  final String id;
  LoadCaution(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirCaution extends CautionEvent {
  final String id;
  RafraichirCaution(this.id);
}

class ResetCautionState extends CautionEvent {}
