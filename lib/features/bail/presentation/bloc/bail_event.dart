abstract class BailEvent {}

class LoadBail extends BailEvent {
  final String id;
  LoadBail(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirBail extends BailEvent {
  final String id;
  RafraichirBail(this.id);
}

/// Activation ; les avertissements éventuels sont publiés par
/// [AvertissementsActivationLoaded].
class ActiverBailEvent extends BailEvent {
  final String id;
  ActiverBailEvent(this.id);
}

class AnnulerBailEvent extends BailEvent {
  final String id;
  final String motif;
  AnnulerBailEvent(this.id, this.motif);
}

class CloturerBailEvent extends BailEvent {
  final String id;
  CloturerBailEvent(this.id);
}

class ResetBailState extends BailEvent {}
