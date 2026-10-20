import 'dart:async';

/// Bus d'événements de session (repris de Sign) : le client HTTP signale une
/// session définitivement expirée sans `BuildContext` ; l'`AuthBloc` l'écoute.
class AuthEventBus {
  static final instance = AuthEventBus._();

  final _deconnexion = StreamController<void>.broadcast();

  Stream<void> get onLogout => _deconnexion.stream;
  AuthEventBus._();

  void emitLogout() => _deconnexion.add(null);
}
