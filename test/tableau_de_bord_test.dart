import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/features/dashboard/data/models/tableau_de_bord_model.dart';

void main() {
  chargesEtIndicateurs();
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

void chargesEtIndicateurs() {
  test('impayés : loyers et charges ; cautions et listes du jour lues', () {
    final d = TableauDeBordModel.depuis({
      'loyers': {'impayes': 100000},
      'charges_impayees': 25000,
      'cautions_detenues': 700000,
      'patrimoine': {'taux_vacance': 12.5},
      'appartement_le_plus_couteux': [
        {
          'apartment_number': 'A1',
          'building_name': 'Almadies',
          'depenses': 5000,
        },
      ],
      'aujourd_hui': [
        {'libelle': 'Paiement PAY-1', 'montant': 100000},
      ],
    }, {});
    expect(d.totalImpayes, 125000);
    expect(d.cautionsDetenues, 700000);
    expect(d.tauxVacance, 12.5);
    expect(d.appartementsCouteux.single.numero, 'A1');
    expect(d.aujourdHui.single.libelle, 'Paiement PAY-1');
  });
}
