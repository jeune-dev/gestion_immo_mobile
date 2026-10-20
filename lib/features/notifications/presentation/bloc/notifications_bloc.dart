import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/compter_notifications_non_lues.dart';
import '../../domain/usecases/marquer_notification_lue.dart';
import '../../domain/usecases/tout_lire.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final CompterNotificationsNonLues compterNotificationsNonLues;
  final MarquerNotificationLue marquerNotificationLue;
  final ToutLire toutLire;

  NotificationsBloc({
    required this.compterNotificationsNonLues,
    required this.marquerNotificationLue,
    required this.toutLire,
  }) : super(NotificationsInitial()) {
    on<LoadCompteurNotifications>(_onLoadCompteur);
    on<MarquerNotificationLueEvent>(_onMarquerNotificationLue);
    on<ToutLireEvent>(_onToutLire);
  }

  Future<void> _onLoadCompteur(
    LoadCompteurNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await compterNotificationsNonLues();
    // Sans réseau : pas de pastille
    emit(CompteurNotificationsLoaded(result.getOrElse(() => 0)));
  }

  Future<void> _onMarquerNotificationLue(
    MarquerNotificationLueEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await marquerNotificationLue(event.id);
    result.fold(
      (failure) => emit(NotificationsError(failure)),
      (_) => emit(NotificationMarqueeLue()),
    );
  }

  Future<void> _onToutLire(
    ToutLireEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await toutLire();
    result.fold(
      (failure) => emit(NotificationsError(failure)),
      (_) => emit(NotificationsSuccess(message: 'Notifications lues')),
    );
  }
}
