import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';

class Bien {
  final String id;
  const Bien(this.id);
}

SourceEntite<Bien> source() => SourceEntite<Bien>(
  charger: (page, q) async => const Right(
    PageResultat<Bien>(items: [Bien('a')], page: 1, totalPages: 1, total: 1),
  ),
  id: (b) => b.id,
  libelle: (b) => 'Bien ${b.id}',
);

void main() {
  testWidgets('le sélecteur d’entité affiche et renvoie les éléments', (
    t,
  ) async {
    EntiteChoisie<dynamic>? choix;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.sombre,
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () async =>
                choix = await choisirEntite(c, source(), titre: 'Bien'),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('ouvrir'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Bien a'), findsOneWidget);
    await t.tap(find.text('Bien a'));
    await t.pumpAndSettle();
    expect(choix?.id, 'a');
  });
}
