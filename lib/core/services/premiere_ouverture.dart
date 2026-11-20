import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// L'onboarding a-t-il déjà été vu sur cet appareil ?
///
/// La marque est posée dans le COFFRE et non dans `SharedPreferences` : au
/// démarrage, `nettoyerStockageLocal()` vide les préférences à chaque
/// ouverture (ménage des versions précédentes). Une marque posée là serait
/// effacée dans la seconde, et les trois écrans d'accueil reviendraient à
/// chaque lancement. Le coffre, lui, n'est touché que pour une seule clé
/// (`gi.cle_donnees_locales`).
class PremiereOuverture {
  static const _cle = 'gi.onboarding_vu';
  final FlutterSecureStorage _stockage;

  /// Lu une fois, puis gardé : le routeur s'en sert à chaque redirection.
  bool? _vu;

  PremiereOuverture([FlutterSecureStorage? stockage])
    : _stockage = stockage ?? const FlutterSecureStorage();

  /// Réponse immédiate une fois la valeur connue ; avant cela, `true` —
  /// l'application ne montre pas l'onboarding tant qu'elle n'est pas sûre
  /// qu'il n'a jamais été vu (le montrer en trop est pire que l'inverse).
  bool get vu => _vu ?? true;

  Future<bool> charger() async {
    if (_vu != null) return _vu!;
    try {
      _vu = (await _stockage.read(key: _cle)) == 'oui';
    } catch (_) {
      // Coffre indisponible : on considère l'onboarding vu plutôt que de le
      // remontrer en boucle.
      _vu = true;
    }
    return _vu!;
  }

  /// Posée dès l'AFFICHAGE du premier écran : fermer l'application au milieu
  /// des trois écrans ne les fait pas revenir.
  Future<void> marquerVu() async {
    _vu = true;
    try {
      await _stockage.write(key: _cle, value: 'oui');
    } catch (_) {
      // Sans écriture, l'onboarding reviendra : ce n'est pas bloquant.
    }
  }
}
