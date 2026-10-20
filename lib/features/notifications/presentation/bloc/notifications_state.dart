import 'package:gestion_immo_mobile/core/errors/failure.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class CompteurNotificationsLoaded extends NotificationsState {
  /// Pastille du bouton (0 sans réseau).
  final int nonLues;
  CompteurNotificationsLoaded(this.nonLues);
}

/// Une notification est marquée comme lue : la liste se recharge.
class NotificationMarqueeLue extends NotificationsState {}

class NotificationsSuccess extends NotificationsState {
  final String message;
  NotificationsSuccess({this.message = 'Opération réussie'});
}

class NotificationsError extends NotificationsState {
  final Failure failure;
  NotificationsError(this.failure);

  String get message => failure.messageComplet;
}
