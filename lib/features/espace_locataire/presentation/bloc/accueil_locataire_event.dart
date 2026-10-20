abstract class AccueilLocataireEvent {}

class LoadAccueilLocataire extends AccueilLocataireEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirAccueilLocataire extends AccueilLocataireEvent {}

class ResetAccueilLocataireState extends AccueilLocataireEvent {}
