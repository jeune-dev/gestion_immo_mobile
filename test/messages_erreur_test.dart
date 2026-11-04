import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/errors/messages.dart';

void main() {
  test('modèle de bail non publié : message clair, sans référence interne', () {
    final message = messageErreur(
      const ServerFailure(
        errorMessage: 'Aucun modèle publié (§ 53.5).',
        code: 'MODELE_NON_PUBLIE',
        status: 409,
      ),
    );
    expect(message, contains('génération de contrat'));
    expect(message, isNot(contains('§')));
  });

  test('les autres erreurs gardent le message de l’API', () {
    expect(
      messageErreur(
        const ServerFailure(errorMessage: 'Refusé', code: 'AUTRE', status: 409),
      ),
      'Refusé',
    );
  });
}
