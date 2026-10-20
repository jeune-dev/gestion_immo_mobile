abstract class ParametresEvent {}

class LoadParametres extends ParametresEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirParametres extends ParametresEvent {}

class ModifierReglagesEvent extends ParametresEvent {
  final Map<String, dynamic> data;
  ModifierReglagesEvent(this.data);
}

class ResetParametresState extends ParametresEvent {}
