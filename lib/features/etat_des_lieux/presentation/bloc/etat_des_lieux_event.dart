abstract class EtatDesLieuxEvent {}

class LoadEtatDesLieux extends EtatDesLieuxEvent {
  final String id;
  LoadEtatDesLieux(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirEtatDesLieux extends EtatDesLieuxEvent {
  final String id;
  RafraichirEtatDesLieux(this.id);
}

class AjouterPieceEvent extends EtatDesLieuxEvent {
  final String id;
  final String nom;
  AjouterPieceEvent(this.id, this.nom);
}

class RenommerPieceEvent extends EtatDesLieuxEvent {
  final String id;
  final String pieceId;
  final String nom;
  RenommerPieceEvent(this.id, this.pieceId, this.nom);
}

class SupprimerPieceEvent extends EtatDesLieuxEvent {
  final String id;
  final String pieceId;
  SupprimerPieceEvent(this.id, this.pieceId);
}

class AjouterElementEvent extends EtatDesLieuxEvent {
  final String id;
  final String pieceId;
  final Map<String, dynamic> data;
  AjouterElementEvent(this.id, this.pieceId, this.data);
}

class PreciserElementEvent extends EtatDesLieuxEvent {
  final String id;
  final String elementId;
  final String? precision;
  PreciserElementEvent(this.id, this.elementId, this.precision);
}

class SupprimerElementEvent extends EtatDesLieuxEvent {
  final String id;
  final String elementId;
  SupprimerElementEvent(this.id, this.elementId);
}

class AjouterPhotoEvent extends EtatDesLieuxEvent {
  final String id;
  final String elementId;
  final String chemin;
  AjouterPhotoEvent(this.id, this.elementId, this.chemin);
}

class SupprimerPhotoEvent extends EtatDesLieuxEvent {
  final String id;
  final String photoId;
  SupprimerPhotoEvent(this.id, this.photoId);
}

class SoumettreEtatDesLieuxEvent extends EtatDesLieuxEvent {
  final String id;
  SoumettreEtatDesLieuxEvent(this.id);
}

class SupprimerEtatDesLieuxEvent extends EtatDesLieuxEvent {
  final String id;
  SupprimerEtatDesLieuxEvent(this.id);
}

/// Correction : la nouvelle version est publiée par
/// [NouvelleVersionLoaded].
class CorrigerEtatDesLieuxEvent extends EtatDesLieuxEvent {
  final String id;
  CorrigerEtatDesLieuxEvent(this.id);
}

class ResetEtatDesLieuxState extends EtatDesLieuxEvent {}
