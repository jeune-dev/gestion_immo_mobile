import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inter est embarquée pour chaque graisse (aucun téléchargement)', () async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // google_fonts signale une police absente des assets par debugPrint
    final erreurs = <String>[];
    final imprimer = debugPrint;
    debugPrint = (m, {wrapWidth}) => erreurs.add(m ?? '');
    try {
      for (final graisse in FontWeight.values) {
        GoogleFonts.inter(fontWeight: graisse);
      }
      try {
        await GoogleFonts.pendingFonts();
      } catch (_) {}
    } finally {
      debugPrint = imprimer;
    }
    expect(erreurs.where((m) => m.contains('unable to load font')), isEmpty);
  });
}
