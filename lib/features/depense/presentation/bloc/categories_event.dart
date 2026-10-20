abstract class CategoriesEvent {}

class LoadCategories extends CategoriesEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirCategories extends CategoriesEvent {}

class DesactiverCategorieEvent extends CategoriesEvent {
  final String categorieId;
  DesactiverCategorieEvent(this.categorieId);
}

class ResetCategoriesState extends CategoriesEvent {}
