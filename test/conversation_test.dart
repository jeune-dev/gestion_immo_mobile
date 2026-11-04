import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/conversation_page.dart';

void main() {
  test('un repère de jour au premier message de chaque journée', () {
    expect(nouveauJour('2026-11-04T10:00:00', null), isTrue);
    expect(nouveauJour('2026-11-04T10:00:00', '2026-11-04T08:00:00'), isFalse);
    expect(nouveauJour('2026-11-04T10:00:00', '2026-11-03T23:00:00'), isTrue);
    expect(nouveauJour(null, '2026-11-03T23:00:00'), isFalse);
  });
}
