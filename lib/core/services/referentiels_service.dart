import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/option_ref.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';

export 'package:gestion_immo_mobile/core/models/option_ref.dart';

/// Raccourci des écrans : le service est enregistré dans `injection_container.dart`.
ReferentielsService get refs => GetIt.instance<ReferentielsService>();

/// Énumérations servies par `GET /referentiels`, gardées en mémoire le temps de la session.
/// Les libellés ne sont JAMAIS réécrits dans l'application (charte § 4, règle 5).
class ReferentielsService extends ChangeNotifier {
  final ApiClient _api;
  ReferentielsService(this._api);

  Map<String, List<OptionRef>> _enumerations = {};

  Future<void> charger() async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.referentiels,
      );
      _appliquer(data);
    } catch (_) {
      // Sans réseau, les codes s'affichent bruts jusqu'au prochain chargement
    }
  }

  void _appliquer(Map<String, dynamic> data) {
    final e = (data['enumerations'] as Map?) ?? {};
    _enumerations = e.map(
      (k, v) => MapEntry(
        k as String,
        (v as List)
            .map((o) => OptionRef('${(o as Map)['code']}', '${o['label']}'))
            .toList(),
      ),
    );
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
