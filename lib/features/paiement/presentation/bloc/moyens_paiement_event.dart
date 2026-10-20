abstract class MoyensPaiementEvent {}

class LoadMoyensPaiement extends MoyensPaiementEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirMoyensPaiement extends MoyensPaiementEvent {}

class ResetMoyensPaiementState extends MoyensPaiementEvent {}
