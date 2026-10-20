abstract class IncidentLocataireEvent {}

class LoadIncidentLocataire extends IncidentLocataireEvent {
  final String id;
  LoadIncidentLocataire(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirIncidentLocataire extends IncidentLocataireEvent {
  final String id;
  RafraichirIncidentLocataire(this.id);
}

class AjouterPieceSignalementEvent extends IncidentLocataireEvent {
  final String id;
  final String chemin;
  final bool video;
  AjouterPieceSignalementEvent(this.id, this.chemin, this.video);
}

class ResetIncidentLocataireState extends IncidentLocataireEvent {}
