abstract class FactureCommuneEvent {}

class LoadFactureCommune extends FactureCommuneEvent {
  final String id;
  LoadFactureCommune(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirFactureCommune extends FactureCommuneEvent {
  final String id;
  RafraichirFactureCommune(this.id);
}

class JoindreDocumentFactureEvent extends FactureCommuneEvent {
  final String id;
  final String chemin;
  JoindreDocumentFactureEvent(this.id, this.chemin);
}

class AnnulerFactureCommuneEvent extends FactureCommuneEvent {
  final String id;
  final String motif;
  AnnulerFactureCommuneEvent(this.id, this.motif);
}

class ResetFactureCommuneState extends FactureCommuneEvent {}
