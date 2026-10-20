abstract class DashboardEvent {}

class LoadDashboard extends DashboardEvent {}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirDashboard extends DashboardEvent {}

class ResetDashboardState extends DashboardEvent {}
