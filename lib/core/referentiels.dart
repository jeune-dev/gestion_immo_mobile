import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';

/// Option d'une énumération métier (contrat, annexe B).
class OptionRef {
  const OptionRef(this.code, this.label);
  final String code;
  final String label;
}

/// Énumérations servies par `GET /referentiels`, mises en cache sur l'appareil.
/// Les libellés ne sont JAMAIS réécrits dans l'application (charte § 4, règle 5).
class Referentiels extends ChangeNotifier {
  Referentiels(this._api);
  final ApiClient _api;
  static const _cle = 'gi.referentiels';

  Map<String, List<OptionRef>> _enumerations = {};

  Future<void> charger() async {
    final p = await SharedPreferences.getInstance();
    final brut = p.getString(_cle);
    if (brut != null) _appliquer(jsonDecode(brut) as Map<String, dynamic>);
    try {
      final data = await _api.get<Map<String, dynamic>>('/referentiels', cache: false);
      _appliquer(data);
      await p.setString(_cle, jsonEncode(data));
    } catch (_) {
      // Hors ligne : la version en cache suffit ; à défaut les codes s'affichent bruts
    }
  }

  void _appliquer(Map<String, dynamic> data) {
    final e = (data['enumerations'] as Map?) ?? {};
    _enumerations = e.map((k, v) => MapEntry(
          k as String,
          (v as List).map((o) => OptionRef('${(o as Map)['code']}', '${o['label']}')).toList(),
        ));
    notifyListeners();
  }

  /// Libellé d'un code (`famille` = clé de l'annexe B en minuscules, ex. `statut_echeance`).
  String libelle(String famille, String? code) {
    if (code == null || code.isEmpty) return '—';
    for (final o in _enumerations[famille] ?? const <OptionRef>[]) {
      if (o.code == code) return o.label;
    }
    return code;
  }

  List<OptionRef> options(String famille) => _enumerations[famille] ?? const [];
}
