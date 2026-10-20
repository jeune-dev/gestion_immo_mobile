abstract class EtatDesLieuxLocataireEvent {}

class LoadEtatDesLieuxLocataire extends EtatDesLieuxLocataireEvent {
  final String id;
  LoadEtatDesLieuxLocataire(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirEtatDesLieuxLocataire extends EtatDesLieuxLocataireEvent {
  final String id;
  RafraichirEtatDesLieuxLocataire(this.id);
}

class AccepterEtatDesLieuxEvent extends EtatDesLieuxLocataireEvent {
  final String id;
  AccepterEtatDesLieuxEvent(this.id);
}

class ContesterEtatDesLieuxEvent extends EtatDesLieuxLocataireEvent {
  final String id;
  final String commentaire;
  ContesterEtatDesLieuxEvent(this.id, this.commentaire);
}

class ResetEtatDesLieuxLocataireState extends EtatDesLieuxLocataireEvent {}
