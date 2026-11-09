import 'dart:typed_data';

import 'package:gestion_immo_mobile/core/services/token_service.dart';

/// Images de l'API déjà téléchargées, gardées en MÉMOIRE seulement (rien n'est
/// écrit sur le téléphone) : une miniature qui revient à l'écran (défilement,
/// retour sur une fiche) n'est pas retéléchargée.
///
/// Les plus anciennes sortent au-delà de [capaciteOctets]. Tout est oublié à la
/// fermeture de la session (changement d'« époque » du [TokenService]).
class CacheImages {
  final TokenService _session;
  final int capaciteOctets;

  /// Ordre d'insertion = ordre d'utilisation : la première entrée est la plus ancienne.
  final _images = <String, Uint8List>{};
  int _taille = 0;
  int _epoque;

  CacheImages(this._session, {this.capaciteOctets = 24 * 1024 * 1024})
    : _epoque = _session.epoque;

  int get taille => _taille;

  Uint8List? lire(String cle) {
    _oublierSiSessionFermee();
    final octets = _images.remove(cle);
    if (octets != null) _images[cle] = octets;
    return octets;
  }

  void ecrire(String cle, Uint8List octets) {
    _oublierSiSessionFermee();
    if (octets.length > capaciteOctets) return;
    final ancienne = _images.remove(cle);
    if (ancienne != null) _taille -= ancienne.length;
    _images[cle] = octets;
    _taille += octets.length;
    while (_taille > capaciteOctets) {
      final plusAncienne = _images.keys.first;
      _taille -= _images.remove(plusAncienne)!.length;
    }
  }

  void _oublierSiSessionFermee() {
    if (_session.epoque == _epoque) return;
    _epoque = _session.epoque;
    _images.clear();
    _taille = 0;
  }
}
