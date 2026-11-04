import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/features/dashboard/data/models/tableau_de_bord_model.dart';

void main() {
  test(
    'avance sur le mois suivant : reste à recevoir nul, encaissé complet',
    () {
      final d = TableauDeBordModel.depuis({
        'mois': '2026-11',
        'loyers': {'a_recevoir': 165000, 'encaisses': 165000, 'impayes': 0},
        'revenus': {'total': 250000},
        'depenses': 0,
        'resultat': 250000,
      }, {});
      expect(d.resteARecevoir, 0);
      expect(d.revenus, 250000);
      expect(d.resultat, (d.revenus ?? 0) - (d.depenses ?? 0));
    },
  );

  test('loyer partiellement payé : reste la différence', () {
    final d = TableauDeBordModel.depuis({
      'loyers': {'a_recevoir': 165000, 'encaisses': 65000},
    }, {});
    expect(d.resteARecevoir, 100000);
  });
}
