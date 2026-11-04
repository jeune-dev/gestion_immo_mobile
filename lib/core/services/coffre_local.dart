import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Chiffre les données gardées sur l'appareil (cache de lecture, opérations hors
/// ligne) : AES-256-GCM, clé dans le Keychain / Keystore.
class CoffreLocal {
  static const _cleStockage = 'gi.cle_donnees_locales';
  static const _prefixe = 'v1:';

  final FlutterSecureStorage _stockage;
  final AesGcm _algo = AesGcm.with256bits();
  SecretKey? _cle;

  CoffreLocal([FlutterSecureStorage? stockage])
    : _stockage = stockage ?? const FlutterSecureStorage();

  static bool estChiffre(String valeur) => valeur.startsWith(_prefixe);

  Future<SecretKey> _charger() async {
    final connue = _cle;
    if (connue != null) return connue;
    final enregistree = await _stockage.read(key: _cleStockage);
    if (enregistree != null) {
      return _cle = SecretKey(base64Decode(enregistree));
    }
    final nouvelle = await _algo.newSecretKey();
    await _stockage.write(
      key: _cleStockage,
      value: base64Encode(await nouvelle.extractBytes()),
    );
    return _cle = nouvelle;
  }

  Future<String> chiffrer(String clair) async {
    final boite = await _algo.encrypt(
      utf8.encode(clair),
      secretKey: await _charger(),
    );
    return '$_prefixe${base64Encode(boite.concatenation())}';
  }

  /// `null` si la valeur n'est pas déchiffrable (ancien format, clé perdue).
  Future<String?> dechiffrer(String valeur) async {
    if (!estChiffre(valeur)) return null;
    try {
      final boite = SecretBox.fromConcatenation(
        base64Decode(valeur.substring(_prefixe.length)),
        nonceLength: _algo.nonceLength,
        macLength: _algo.macAlgorithm.macLength,
      );
      return utf8.decode(
        await _algo.decrypt(boite, secretKey: await _charger()),
      );
    } catch (_) {
      return null;
    }
  }
}
