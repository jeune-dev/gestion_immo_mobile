import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';

/// Luminance relative WCAG 2.1 d'une couleur opaque.
double _luminance(Color c) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

/// Rapport de contraste WCAG entre deux couleurs opaques (1 → 21).
double _contraste(Color a, Color b) {
  final (x, y) = (_luminance(a), _luminance(b));
  final (clair, fonce) = x > y ? (x, y) : (y, x);
  return (clair + 0.05) / (fonce + 0.05);
}

void main() {
  // Le bandeau de marque porte le logo blanc, le nom et les titres des écrans
  // du parcours : si on l'éclaircit, c'est ce blanc qui devient illisible, et
  // rien d'autre dans l'application ne s'en plaindra. D'où ce garde-fou sur
  // les deux extrémités du dégradé, dans les deux modes.
  group('contraste du dégradé de marque', () {
    final degrades = {
      'clair': AppColors.degradeMarque,
      'sombre': AppColors.degradeMarqueSombre,
    };

    for (final (mode, degrade) in degrades.entries.map((e) => (e.key, e.value))) {
      for (final fond in degrade.colors) {
        final teinte =
            '#${(fond.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

        test('mode $mode, $teinte : le blanc reste lisible', () {
          expect(_contraste(Colors.white, fond), greaterThanOrEqualTo(7));
        });

        test('mode $mode, $teinte : le vert du logo reste lisible', () {
          expect(
            _contraste(AppColors.vertLogo, fond),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }
  });
}
