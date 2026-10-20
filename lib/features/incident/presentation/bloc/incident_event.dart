abstract class IncidentEvent {}

class LoadIncident extends IncidentEvent {
  final String id;
  LoadIncident(this.id);
}

/// Relecture sans repasser par l'écran de chargement (tirer pour
/// rafraîchir, retour d'un écran ouvert depuis la fiche).
class RafraichirIncident extends IncidentEvent {
  final String id;
  RafraichirIncident(this.id);
}

class AnalyserIncidentEvent extends IncidentEvent {
  final String id;
  final String? note;
  AnalyserIncidentEvent(this.id, this.note);
}

class ResoudreIncidentEvent extends IncidentEvent {
  final String id;
  final String? note;
  ResoudreIncidentEvent(this.id, this.note);
}

class RejeterIncidentEvent extends IncidentEvent {
  final String id;
  final String motif;
  RejeterIncidentEvent(this.id, this.motif);
}

class ResetIncidentState extends IncidentEvent {}
