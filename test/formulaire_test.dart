import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';

void main() {
  Future<List<Map<String, dynamic>>> soumettre(
    WidgetTester tester,
    Champ champ,
    String saisie,
  ) async {
    final envois = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: EcranFormulaire(
          titre: 'Test',
          champs: [champ],
          envoyer: (corps) async => envois.add(corps),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), saisie);
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    return envois;
  }

  testWidgets('le bouton d’envoi reste au-dessus du clavier', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: EcranFormulaire(
            titre: 'Test',
            champs: const [Champ('ville', 'Ville')],
            envoyer: (_) async {},
          ),
        ),
      ),
    );
    final bouton = tester.getBottomLeft(find.text('Enregistrer'));
    expect(
      bouton.dy,
      lessThan(
        tester.view.physicalSize.height / tester.view.devicePixelRatio - 300,
      ),
    );
  });

  testWidgets('longueur minimale du schéma de l’API', (tester) async {
    const champ = Champ('response', 'Réponse', minLongueur: 5);
    expect(await soumettre(tester, champ, 'abc'), isEmpty);
    expect(find.text('5 caractères minimum'), findsOneWidget);
  });

  testWidgets('format du numéro de transaction', (tester) async {
    const champ = Champ(
      'provider_transaction_id',
      'Numéro',
      format: (r'^[A-Za-z0-9_\-./]+$', 'Format invalide'),
    );
    expect(await soumettre(tester, champ, 'AB 12'), isEmpty);
    expect(find.text('Format invalide'), findsOneWidget);
  });

  testWidgets('une saisie conforme est envoyée', (tester) async {
    const champ = Champ('response', 'Réponse', minLongueur: 5);
    final envois = await soumettre(tester, champ, 'Bonjour');
    expect(envois, [
      {'response': 'Bonjour'},
    ]);
  });

  group('contrôles du moteur', () {
    Future<void> erreur(
      WidgetTester t,
      Champ c,
      String saisie,
      String attendu,
    ) async {
      expect(await soumettre(t, c, saisie), isEmpty, reason: saisie);
      expect(find.text(attendu), findsOneWidget, reason: saisie);
    }

    testWidgets('téléphone : refusé puis envoyé au format de l’API', (t) async {
      const c = Champ('phone', 'Téléphone', type: TypeChamp.telephone);
      await erreur(t, c, '77 12', 'Le numéro doit contenir 9 chiffres');
      expect(await soumettre(t, c, '77 123 45 67'), [
        {'phone': '+221771234567'},
      ]);
    });

    testWidgets('e-mail : refusé puis envoyé en minuscules', (t) async {
      const c = Champ('email', 'E-mail', type: TypeChamp.email);
      await erreur(t, c, 'awa@demo', 'E-mail invalide');
      expect(await soumettre(t, c, 'Awa@Demo.SN'), [
        {'email': 'awa@demo.sn'},
      ]);
    });

    testWidgets('nom : chiffres refusés, accents et tirets acceptés', (
      t,
    ) async {
      const c = Champ('first_name', 'Prénom', type: TypeChamp.nom);
      await erreur(
        t,
        c,
        'Awa2',
        'Lettres, espaces, apostrophes et tirets uniquement',
      );
      expect(await soumettre(t, c, "Mame-Diarra N’Diaye"), [
        {'first_name': "Mame-Diarra N’Diaye"},
      ]);
    });

    testWidgets('montant : plafonné, avec le message en FCFA', (t) async {
      const c = Champ('amount', 'Montant', type: TypeChamp.montant, max: 1000);
      expect(await soumettre(t, c, '2000'), isEmpty);
      expect(find.textContaining('Maximum 1'), findsOneWidget);
      expect(await soumettre(t, c, '1000'), [
        {'amount': 1000},
      ]);
    });

    testWidgets('décimal : strictement positif et précision de l’API', (
      t,
    ) async {
      const c = Champ(
        'surface',
        'Surface',
        type: TypeChamp.decimal,
        positif: true,
        decimales: 2,
      );
      await erreur(t, c, '0', 'Doit être supérieur à 0');
      await erreur(t, c, '12,345', '2 décimales maximum');
      expect(await soumettre(t, c, '12,5'), [
        {'surface': 12.5},
      ]);
    });

    testWidgets(
      'entier : le signe moins n’est accepté que si le minimum est négatif',
      (t) async {
        const c = Champ('n', 'Nombre', type: TypeChamp.entier);
        await soumettre(t, c, '-5');
        expect(find.text('5'), findsOneWidget);
      },
    );

    testWidgets('champ obligatoire sous condition', (t) async {
      final envois = <Map<String, dynamic>>[];
      await t.pumpWidget(
        MaterialApp(
          home: EcranFormulaire(
            titre: 'Test',
            initial: const {'mode': 'preuve'},
            champs: [
              const Champ('mode', 'Mode'),
              Champ(
                'numero',
                'Numéro',
                obligatoireSi: (v) => v['mode'] == 'preuve',
              ),
            ],
            envoyer: (c) async => envois.add(c),
          ),
        ),
      );
      await t.tap(find.text('Enregistrer'));
      await t.pump();
      expect(find.text('Obligatoire'), findsOneWidget);
      expect(envois, isEmpty);
    });

    Future<List<Map<String, dynamic>>> avecDates(
      WidgetTester t,
      List<Champ> champs,
      Map<String, dynamic> initial,
    ) async {
      final envois = <Map<String, dynamic>>[];
      await t.pumpWidget(
        MaterialApp(
          home: EcranFormulaire(
            titre: 'Test',
            initial: initial,
            champs: champs,
            envoyer: (c) async => envois.add(c),
          ),
        ),
      );
      await t.tap(find.text('Enregistrer'));
      await t.pump();
      return envois;
    }

    testWidgets('dates : fin après début, sans futur, erreur sous le champ', (
      t,
    ) async {
      const champs = [
        Champ('du', 'Début', type: TypeChamp.date, obligatoire: true),
        Champ(
          'au',
          'Fin',
          type: TypeChamp.date,
          apresChamp: 'du',
          apresStrict: true,
        ),
      ];
      expect(
        await avecDates(t, champs, {'du': '2026-05-10', 'au': '2026-05-10'}),
        isEmpty,
      );
      expect(find.text('Doit être après « Début »'), findsOneWidget);

      await t.pumpWidget(const SizedBox());
      const payee = [
        Champ('paid_on', 'Date', type: TypeChamp.date, pasDansLeFutur: true),
      ];
      expect(await avecDates(t, payee, {'paid_on': '2099-01-01'}), isEmpty);
      expect(find.text('Ne peut pas être dans le futur'), findsOneWidget);

      await t.pumpWidget(const SizedBox());
      const requise = [
        Champ('jour', 'Jour', type: TypeChamp.date, obligatoire: true),
      ];
      expect(await avecDates(t, requise, const {}), isEmpty);
      expect(find.text('Obligatoire'), findsOneWidget);
    });

    testWidgets('contrôle sur plusieurs champs : bloque l’envoi', (t) async {
      final envois = <Map<String, dynamic>>[];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => EcranFormulaire(
                titre: 'Test',
                champs: const [Champ('a', 'A')],
                controle: (c) => c['a'] == null ? 'Indiquez A' : null,
                envoyer: (c) async => envois.add(c),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Enregistrer'));
      await t.pump();
      expect(envois, isEmpty);
      expect(find.text('Indiquez A'), findsOneWidget);
    });
  });
}
