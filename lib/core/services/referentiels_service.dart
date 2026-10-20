import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/option_ref.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';

export 'package:gestion_immo_mobile/core/models/option_ref.dart';

/// Raccourci des écrans : le service est enregistré dans `injection_container.dart`.
ReferentielsService get refs => GetIt.instance<ReferentielsService>();

/// Énumérations servies par `GET /referentiels`, mises en cache sur l'appareil.
/// Les libellés ne sont JAMAIS réécrits dans l'application (charte § 4, règle 5).
class ReferentielsService extends ChangeNotifier {
  final ApiClient _api;
  ReferentielsService(this._api);
  static const _cle = 'gi.referentiels';

  Map<String, List<OptionRef>> _enumerations = {};

  Future<void> charger() async {
    final p = await SharedPreferences.getInstance();
    final brut = p.getString(_cle);
    if (brut != null) _appliquer(jsonDecode(brut) as Map<String, dynamic>);
    try {
      final data = await _api
          .get<Map<String, dynamic>>(ApiEndpoints.referentiels, cache: false);
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
        (v as List)
            .map((o) => OptionRef('${(o as Map)['code']}', '${o['label']}'))
            .toList()));
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
