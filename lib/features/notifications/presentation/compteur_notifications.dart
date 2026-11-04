import 'package:flutter/foundation.dart';

import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/compter_notifications_non_lues.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/usecases/marquer_notification_lue.dart';

/// Nombre de notifications non lues, partagé par toutes les cloches de l'application.
class CompteurNotifications {
  CompteurNotifications._();

  static final valeur = ValueNotifier<int>(0);

  static Future<void> rafraichir() async {
    final r = await sl<CompterNotificationsNonLues>()();
    // Sans réseau : la pastille garde sa dernière valeur.
    r.fold((_) {}, (n) => valeur.value = n);
  }

  /// Ouvrir une conversation lit ses messages : ses notifications deviennent lues.
  static Future<void> lireConversation(String filId) async {
    var page = 1;
    var suite = true;
    while (suite) {
      final r = await sl<GetNotifications>()(page: page, nonLues: true);
      final resultat = r.fold((_) => null, (p) => p);
      if (resultat == null) break;
      for (final n in resultat.items.where((n) => n.filId == filId)) {
        await sl<MarquerNotificationLue>()(n.id);
      }
      suite = resultat.aSuite;
      page++;
    }
    await rafraichir();
  }
}
