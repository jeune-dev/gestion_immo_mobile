import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/utils/journal.dart';
import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/entities/notification_app.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/widgets/ouvrir_notification.dart';
import 'package:gestion_immo_mobile/injection_container.dart';

/// Notifications push : enregistrement de l'appareil auprès de l'API, et
/// ouverture de l'écran concerné quand l'utilisateur appuie sur la
/// notification.
///
/// Firebase est démarré par `demarrerFirebase()` au lancement
/// (`core/services/remontee_erreurs.dart`) : sans lui, ce service ne fait
/// rien et le dit une fois dans le journal de débogage. Un échec ne gêne
/// jamais l'utilisateur — le push reste un complément de la liste interne.
///
/// Désactivable pour un build particulier avec
/// `--dart-define=PUSH_ACTIVE=false`.
class PushService {
  static const _actif = bool.fromEnvironment('PUSH_ACTIVE', defaultValue: true);

  final ApiClient _api;
  StreamSubscription<String>? _renouvellement;
  StreamSubscription<RemoteMessage>? _ouvertures;
  String? _jeton;

  PushService(this._api);

  String get _plateforme =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> _enregistrer(String jeton) async {
    _jeton = jeton;
    await _api.post<dynamic>(
      ApiEndpoints.compteAppareils,
      body: {'token': jeton, 'platform': _plateforme},
    );
  }

  /// À la connexion.
  Future<void> demarrer() async {
    if (!_actif || _renouvellement != null) return;
    if (Firebase.apps.isEmpty) {
      journalDebug('Firebase absent : notifications push inactives.');
      return;
    }
    try {
      final messagerie = FirebaseMessaging.instance;
      await messagerie.requestPermission();
      // Jeton FCM classique : c'est lui que le backend vise (firebase-admin, champ `token`).
      // ignore: deprecated_member_use
      final jeton = await messagerie.getToken();
      if (jeton != null) await _enregistrer(jeton);
      // ignore: deprecated_member_use
      _renouvellement = messagerie.onTokenRefresh.listen(
        (nouveau) => _enregistrer(nouveau).catchError(
          (Object e) => journalDebug('Jeton push non réenregistré : $e'),
        ),
      );
      await _ecouterOuvertures(messagerie);
    } catch (e) {
      journalDebug('Notifications push indisponibles : $e');
    }
  }

  /// Les deux façons d'arriver dans l'application par une notification.
  ///
  /// `onMessageOpenedApp` : l'application était en arrière-plan, elle revient.
  /// `getInitialMessage` : elle était FERMÉE, et c'est l'appui qui l'a lancée —
  /// le flux ci-dessus n'émet alors rien, ce message n'existe qu'ici et une
  /// seule fois. Sans ce second appel, un appui sur une notification, téléphone
  /// rangé depuis la veille, ouvre l'application sur son tableau de bord.
  ///
  /// Rien n'est écouté pour l'application au premier plan : le backend envoie
  /// une charge `notification`, que ni Android ni iOS n'affichent dans ce cas,
  /// et dessiner la bannière soi-même demanderait `flutter_local_notifications`.
  /// L'écran de notifications et sa pastille tiennent ce rôle.
  Future<void> _ecouterOuvertures(FirebaseMessaging messagerie) async {
    _ouvertures ??= FirebaseMessaging.onMessageOpenedApp.listen(_ouvrir);
    final initial = await messagerie.getInitialMessage();
    if (initial != null) _ouvrir(initial);
  }

  /// `data` de FCM → notification interne → écran, par le même chemin que la
  /// liste des notifications. Le backend envoie `type` et `notification_id`
  /// avec les identifiants de l'entité concernée (voir
  /// `gestion_immo_back/src/modules/notification/service/notification.service.js`).
  void _ouvrir(RemoteMessage message) {
    final donnees = message.data;
    final type = donnees['type'] as String?;
    if (type == null) return;
    final notification = NotificationApp(
      id: '${donnees['notification_id'] ?? ''}',
      type: type,
      titre: message.notification?.title ?? '',
      corps: message.notification?.body ?? '',
      donnees: donnees,
    );
    _apresPremiereImage(() {
      final context = AppRouter.navigateur.currentContext;
      if (context == null) return;
      final locataire = sl<AuthBloc>().state.compte?.estLocataire ?? false;
      if (!notificationOuvrable(notification, locataire: locataire)) return;
      ouvrirNotification(context, notification, locataire: locataire);
    });
  }

  /// Au démarrage à froid, le navigateur n'existe pas encore quand le message
  /// initial est lu : on attend la première image, sans quoi `currentContext`
  /// est nul et l'appui ne mène nulle part.
  void _apresPremiereImage(VoidCallback action) {
    if (AppRouter.navigateur.currentContext != null) return action();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  /// À la déconnexion, tant que la session est encore valide.
  Future<void> arreter() async {
    final jeton = _jeton;
    await _renouvellement?.cancel();
    _renouvellement = null;
    await _ouvertures?.cancel();
    _ouvertures = null;
    _jeton = null;
    if (jeton == null) return;
    try {
      await _api.delete<dynamic>(
        ApiEndpoints.compteAppareils,
        body: {'token': jeton},
      );
    } catch (_) {
      // Sans réseau : le serveur retirera le jeton à son prochain envoi refusé.
    }
  }
}
