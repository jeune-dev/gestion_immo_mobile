import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;

  /// Vrai à chaque retour d'une connexion (Wi-Fi, données mobiles…).
  Stream<bool> get onChange;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  static bool _connecte(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  @override
  Future<bool> get isConnected async =>
      _connecte(await connectivity.checkConnectivity());

  @override
  Stream<bool> get onChange =>
      connectivity.onConnectivityChanged.map(_connecte).distinct();
}
