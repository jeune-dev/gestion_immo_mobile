import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';

/// Enregistre le téléphone auprès de l'API pour recevoir les notifications push.
///
/// Inactif tant que l'application n'est pas construite avec
/// `--dart-define=PUSH_ACTIVE=true`, ce qui exige les fichiers Firebase
/// (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`).
/// Un échec ne gêne jamais l'utilisateur : le push reste un complément.
class PushService {
  static const _actif = bool.fromEnvironment('PUSH_ACTIVE');

  final ApiClient _api;
  StreamSubscription<String>? _renouvellement;
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
    try {
      await Firebase.initializeApp();
      final messagerie = FirebaseMessaging.instance;
      await messagerie.requestPermission();
      // Jeton FCM classique : c'est lui que le backend vise (firebase-admin, champ `token`).
      // ignore: deprecated_member_use
      final jeton = await messagerie.getToken();
      if (jeton != null) await _enregistrer(jeton);
      // ignore: deprecated_member_use
      _renouvellement = messagerie.onTokenRefresh.listen(
        (nouveau) => _enregistrer(nouveau).catchError((_) {}),
      );
    } catch (e) {
      debugPrint('Notifications push indisponibles : $e');
    }
  }

  /// À la déconnexion, tant que la session est encore valide.
  Future<void> arreter() async {
    final jeton = _jeton;
    await _renouvellement?.cancel();
    _renouvellement = null;
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
