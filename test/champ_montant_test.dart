import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';

/// Les montants partagent leur ligne deux par deux (`moitie: true`) : charges
/// et caution, par exemple. Avec « FCFA » posé en suffixe, il ne restait pas
/// la largeur d'un montant à sept chiffres, et une caution de 3 300 000 FCFA
/// s'affichait tronquée — le propriétaire ne pouvait plus relire ce qu'il
/// venait de saisir. L'unité passe donc dans l'étiquette sur ces champs-là.
void main() {
  Future<void> poser(WidgetTester t, List<Champ> champs) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.clair,
        home: EcranFormulaire(
          titre: 'Bail',
          champs: champs,
          initial: const {'deposit_amount': 3300000, 'rent_amount': 165000},
          envoyer: (_) async {},
        ),
      ),
    );
    await t.pump();
  }

  testWidgets('demi-champ : l’unité est dans l’étiquette, pas en suffixe', (
    t,
  ) async {
    await poser(t, const [
      Champ('charges_amount', 'Charges', type: TypeChamp.montant, moitie: true),
      Champ('deposit_amount', 'Caution', type: TypeChamp.montant, moitie: true),
    ]);

    expect(find.text('Caution (FCFA)'), findsOneWidget);
    expect(find.text('Charges (FCFA)'), findsOneWidget);
    // Plus de suffixe : c'est lui qui rognait la place.
    expect(find.text('FCFA'), findsNothing);
    // Le montant reste affiché en entier (espaces insécables du formateur).
    expect(find.text(nombre(3300000)), findsOneWidget);
  });

  testWidgets('champ pleine largeur : l’unité reste en suffixe', (t) async {
    await poser(t, const [
      Champ('rent_amount', 'Loyer', type: TypeChamp.montant),
    ]);

    expect(find.text('FCFA'), findsOneWidget);
    expect(find.text('Loyer (FCFA)'), findsNothing);
    expect(find.text('Loyer'), findsOneWidget);
  });
}
