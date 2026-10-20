abstract class TravauxEvent {}

class LoadTravaux extends TravauxEvent {
  final String id;
  LoadTravaux(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirTravaux extends TravauxEvent {
  final String id;
  RafraichirTravaux(this.id);
}

class AjouterPhotoTravauxEvent extends TravauxEvent {
  final String id;
  final String phase;
  final String chemin;
  AjouterPhotoTravauxEvent(this.id, this.phase, this.chemin);
}

class SupprimerPhotoTravauxEvent extends TravauxEvent {
  final String id;
  final String photoId;
  SupprimerPhotoTravauxEvent(this.id, this.photoId);
}

class ResetTravauxState extends TravauxEvent {}
