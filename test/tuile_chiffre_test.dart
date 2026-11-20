import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';

/// Les tuiles du tableau de bord vivent dans une grille à hauteur imposée
/// (`childAspectRatio: 1.18`). Une légende un peu longue y passait à la ligne
/// et débordait la carte : bandes jaunes en travers de l'écran d'accueil, sur
/// le premier écran que voit un propriétaire.
void main() {
  /// Une cellule de la grille du tableau de bord, à la taille qu'elle a sur un
  /// téléphone étroit — c'est là que la place manque en premier.
  Future<void> poser(
    WidgetTester t,
    String sous, {
    double largeur = 150,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.clair,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: largeur,
              height: largeur / 1.18,
              child: ChiffreCle(
                libelle: 'Encaissé',
                valeur: '1 250 000 FCFA',
                icone: Icons.check_circle_outline,
                ton: TonStatut.succes,
                sous: sous,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  for (final (nom, sous) in [
    ('courte', 'Reçu ce mois-ci'),
    ('longue', 'Reçu ce mois-ci, tout compris'),
    ('très longue', 'dont 1 250 000 FCFA de charges et de régularisations'),
  ]) {
    testWidgets('légende $nom : la tuile ne déborde pas', (t) async {
      await poser(t, sous);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('la légende cède la place plutôt que de pousser la carte', (
    t,
  ) async {
    await poser(t, 'dont 1 250 000 FCFA de charges et de régularisations');
    final texte = t.widget<Text>(
      find.textContaining('de charges', findRichText: false),
    );
    expect(texte.maxLines, isNotNull);
    expect(texte.overflow, TextOverflow.ellipsis);
  });

  testWidgets('la valeur reste lisible en entier', (t) async {
    await poser(t, 'Reçu ce mois-ci');
    expect(find.text('1 250 000 FCFA'), findsOneWidget);
    expect(find.text('Encaissé'), findsOneWidget);
  });
}
