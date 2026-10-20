abstract class LocataireEvent {}

class LoadLocataire extends LocataireEvent {
  final String id;
  LoadLocataire(this.id);
}

/// Relecture de la fiche sans repasser par l'écran de chargement
/// (tirer pour rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirLocataire extends LocataireEvent {
  final String id;
  RafraichirLocataire(this.id);
}

class SupprimerLocataireEvent extends LocataireEvent {
  final String id;
  SupprimerLocataireEvent(this.id);
}

/// Nouveau code d'invitation pour l'application.
class InviterLocataireEvent extends LocataireEvent {
  final String id;
  InviterLocataireEvent(this.id);
}

class EnregistrerConsentementWhatsappEvent extends LocataireEvent {
  final String id;
  EnregistrerConsentementWhatsappEvent(this.id);
}

class ResetLocataireState extends LocataireEvent {}
