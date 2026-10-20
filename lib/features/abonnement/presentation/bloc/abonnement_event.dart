abstract class AbonnementEvent {}

class LoadAbonnement extends AbonnementEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirAbonnement extends AbonnementEvent {}

/// Souscription : l'URL de paiement PayDunya est publiée par
/// [LienPaiementAbonnementLoaded].
class SouscrireAbonnementEvent extends AbonnementEvent {
  final String planCode;
  final int mois;
  final String? portefeuille;
  SouscrireAbonnementEvent(this.planCode, this.mois, this.portefeuille);
}

class ResetAbonnementState extends AbonnementEvent {}
