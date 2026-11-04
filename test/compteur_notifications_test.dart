import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/entities/notification_app.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/compter_notifications_non_lues.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/marquer_notification_lue.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/compteur_notifications.dart';

NotificationApp _message(String id, String fil) => NotificationApp(
  id: id,
  type: 'nouveau_message',
  titre: 't',
  corps: 'c',
  donnees: {'thread_id': fil},
);

class _Depot implements NotificationsRepository {
  final nonLues = [_message('1', 'A'), _message('2', 'B'), _message('3', 'A')];

  @override
  Future<Either<Failure, PageResultat<NotificationApp>>> getNotifications({
    required int page,
    bool nonLues = false,
  }) async => Right(
    PageResultat(
      items: List.of(this.nonLues),
      page: page,
      totalPages: 1,
      total: this.nonLues.length,
    ),
  );

  @override
  Future<Either<Failure, int>> compterNonLues() async => Right(nonLues.length);

  @override
  Future<Either<Failure, void>> marquerLue(String id) async {
    nonLues.removeWhere((n) => n.id == id);
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'ouvrir une conversation lit ses notifications et baisse le compteur',
    () async {
      final depot = _Depot();
      GetIt.instance
        ..registerSingleton(CompterNotificationsNonLues(depot))
        ..registerSingleton(GetNotifications(depot))
        ..registerSingleton(MarquerNotificationLue(depot));
      await CompteurNotifications.rafraichir();
      expect(CompteurNotifications.valeur.value, 3);

      await CompteurNotifications.lireConversation('A');
      expect(depot.nonLues.map((n) => n.id), ['2']);
      expect(CompteurNotifications.valeur.value, 1);
    },
  );
}
