abstract class CautionsLocataireEvent {}

class LoadCautionsLocataire extends CautionsLocataireEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirCautionsLocataire extends CautionsLocataireEvent {}

class ContesterRetenueEvent extends CautionsLocataireEvent {
  final String mouvementId;
  final String message;
  ContesterRetenueEvent(this.mouvementId, this.message);
}

class ResetCautionsLocataireState extends CautionsLocataireEvent {}
