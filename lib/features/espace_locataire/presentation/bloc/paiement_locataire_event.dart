abstract class PaiementLocataireEvent {}

class LoadPaiementLocataire extends PaiementLocataireEvent {
  final String bailId;
  LoadPaiementLocataire(this.bailId);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirPaiementLocataire extends PaiementLocataireEvent {
  final String bailId;
  RafraichirPaiementLocataire(this.bailId);
}

/// Paiement intégré : la demande créée est publiée par
/// [DemandePaiementLoaded].
class PayerEnLigneEvent extends PaiementLocataireEvent {
  final String bailId;
  final String echeanceId;
  final int montant;
  final String portefeuille;
  PayerEnLigneEvent(
      this.bailId, this.echeanceId, this.montant, this.portefeuille);
}

class ResetPaiementLocataireState extends PaiementLocataireEvent {}
