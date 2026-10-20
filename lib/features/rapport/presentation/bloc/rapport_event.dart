abstract class RapportEvent {}

class LoadRapport extends RapportEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour rafraîchir).
class RafraichirRapport extends RapportEvent {}
