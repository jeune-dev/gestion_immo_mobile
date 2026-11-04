import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/accueil_locataire_page.dart';

void main() {
  test('délai d’échéance lisible, à la journée près', () {
    final maintenant = DateTime(2026, 11, 4, 23, 30);
    expect(delaiEcheance('2026-11-04', maintenant), 'Aujourd’hui');
    expect(delaiEcheance('2026-11-05', maintenant), 'Demain');
    expect(delaiEcheance('2026-11-09', maintenant), 'Dans 5 jours');
    expect(delaiEcheance('2026-11-03', maintenant), 'En retard d’un jour');
    expect(delaiEcheance('2026-11-01', maintenant), 'En retard de 3 jours');
    expect(delaiEcheance(null, maintenant), isNull);
    expect(delaiEcheance('illisible', maintenant), isNull);
  });
}
