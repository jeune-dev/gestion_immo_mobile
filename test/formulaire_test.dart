import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';

void main() {
  Future<List<Map<String, dynamic>>> soumettre(
      WidgetTester tester, Champ champ, String saisie) async {
    final envois = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
      home: EcranFormulaire(
        titre: 'Test',
        champs: [champ],
        envoyer: (corps) async => envois.add(corps),
      ),
    ));
    await tester.enterText(find.byType(TextFormField), saisie);
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    return envois;
  }

  testWidgets('longueur minimale du schéma de l’API', (tester) async {
    const champ = Champ('response', 'Réponse', minLongueur: 5);
    expect(await soumettre(tester, champ, 'abc'), isEmpty);
    expect(find.text('5 caractères minimum'), findsOneWidget);
  });

  testWidgets('format du numéro de transaction', (tester) async {
    const champ = Champ('provider_transaction_id', 'Numéro',
        format: (r'^[A-Za-z0-9_\-./]+$', 'Format invalide'));
    expect(await soumettre(tester, champ, 'AB 12'), isEmpty);
    expect(find.text('Format invalide'), findsOneWidget);
  });

  testWidgets('une saisie conforme est envoyée', (tester) async {
    const champ = Champ('response', 'Réponse', minLongueur: 5);
    final envois = await soumettre(tester, champ, 'Bonjour');
    expect(envois, [
      {'response': 'Bonjour'}
    ]);
  });
}
