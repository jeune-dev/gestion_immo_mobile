abstract class NotificationsEvent {}

/// Nombre de notifications non lues (pastille du bouton).
class LoadCompteurNotifications extends NotificationsEvent {}

class MarquerNotificationLueEvent extends NotificationsEvent {
  final String id;
  MarquerNotificationLueEvent(this.id);
}

class ToutLireEvent extends NotificationsEvent {}
