import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Deux `FloatingActionButton` sans `heroTag` qui se retrouvent dans la même
/// transition partagent le tag Hero par défaut. Flutter lève alors une
/// assertion en plein milieu de l'animation, et l'arbre de widgets ne s'en
/// relève pas : écran rouge.
///
/// C'est arrivé en vrai, au retour du formulaire « Nouvel appartement » vers
/// la fiche de l'immeuble. Le défaut ne se voit ni à la compilation ni à
/// l'analyse : il faut traverser l'écran. D'où ce contrôle sur les sources,
/// qui coûte quelques millisecondes et couvre toute l'application.
void main() {
  test('chaque bouton flottant porte un heroTag', () {
    final fautifs = <String>[];

    for (final fichier in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lignes = fichier.readAsLinesSync();
      for (var i = 0; i < lignes.length; i++) {
        if (!lignes[i].contains('FloatingActionButton')) continue;
        if (lignes[i].contains('floatingActionButtonTheme')) continue;

        // Le tag est passé dans les arguments qui suivent l'ouverture de la
        // parenthèse ; on regarde la poignée de lignes suivantes.
        final suite = lignes.skip(i).take(12).join('\n');
        if (!suite.contains('heroTag')) {
          fautifs.add('${fichier.path}:${i + 1}');
        }
      }
    }

    expect(
      fautifs,
      isEmpty,
      reason:
          'Boutons flottants sans heroTag — deux d’entre eux dans la même '
          'transition feraient virer l’écran au rouge :\n${fautifs.join('\n')}',
    );
  });
}
