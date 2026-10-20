import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage des jetons (contrat § 0 « Authentification ») :
/// - le refresh token dans le coffre de l'appareil (Keychain / Keystore) ;
/// - le jeton d'accès (15 min) en mémoire seulement.
class TokenService {
  static const _cleRefresh = 'gi.refresh_token';
  final FlutterSecureStorage _stockage;

  String? accessToken;
  String? _refreshToken;
  bool _charge = false;

  TokenService([FlutterSecureStorage? stockage])
      : _stockage = stockage ?? const FlutterSecureStorage();

  Future<String?> lireRefresh() async {
    if (!_charge) {
      _refreshToken = await _stockage.read(key: _cleRefresh);
      _charge = true;
    }
    return _refreshToken;
  }

  /// Enregistre une nouvelle session. Le refresh token tourne à chaque usage :
  /// on conserve toujours le DERNIER reçu.
  Future<void> enregistrer({required String access, String? refresh}) async {
    accessToken = access;
    if (refresh != null) {
      _refreshToken = refresh;
      _charge = true;
      await _stockage.write(key: _cleRefresh, value: refresh);
    }
  }

  Future<void> effacer() async {
    accessToken = null;
    _refreshToken = null;
    _charge = true;
    await _stockage.delete(key: _cleRefresh);
  }
}
