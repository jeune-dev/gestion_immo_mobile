import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';

/// Dégradé de marque du mode en cours (bleu nuit → roi → ciel).
LinearGradient degradeMarque(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.degradeMarqueSombre
    : AppColors.degradeMarque;

/// Fond des barres et des en-têtes : dégradé du logo.
///
/// ```dart
/// AppBar(flexibleSpace: const FondMarque(), title: ...)
/// ```
class FondMarque extends StatelessWidget {
  final Widget? child;
  const FondMarque({super.key, this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: degradeMarque(context)),
    child: child ?? const SizedBox.expand(),
  );
}

/// Carte mise en avant (logement du locataire, solde…) : dégradé du logo,
/// coins arrondis et ombre bleu nuit.
class CarteMarque extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CarteMarque({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.espaceLg + 4),
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: degradeMarque(context),
      borderRadius: BorderRadius.circular(AppTheme.rayonCarte),
      boxShadow: const [
        BoxShadow(
          color: Color(0x400B2A5B),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.rayonCarte),
      child: Padding(padding: padding, child: child),
    ),
  );
}
