abstract class ArtisanEvent {}

class LoadArtisan extends ArtisanEvent {
  final String id;
  LoadArtisan(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirArtisan extends ArtisanEvent {
  final String id;
  RafraichirArtisan(this.id);
}

class DefinirActiviteArtisanEvent extends ArtisanEvent {
  final String id;
  final bool actif;
  DefinirActiviteArtisanEvent(this.id, this.actif);
}

class SupprimerArtisanEvent extends ArtisanEvent {
  final String id;
  SupprimerArtisanEvent(this.id);
}

class ResetArtisanState extends ArtisanEvent {}
