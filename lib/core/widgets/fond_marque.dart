import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart' as format;

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
  Widget build(BuildContext context) => DecoratedBox(
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

/// En-tête d'une fiche : surtitre, statut, grand montant et sous-titre sur la
/// carte de marque (échéance, quittance, charge, caution…).
class CarteMontant extends StatelessWidget {
  final String surtitre;
  final num? montant;
  final String? sousTitre;

  /// À droite du surtitre, en général la pastille de statut.
  final Widget? statut;

  /// Lignes ajoutées sous le sous-titre (progression d'un versement…).
  final List<Widget> pied;

  const CarteMontant({
    super.key,
    required this.surtitre,
    required this.montant,
    this.sousTitre,
    this.statut,
    this.pied = const [],
  });

  @override
  Widget build(BuildContext context) => CarteMarque(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                surtitre.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (statut != null) statut!,
          ],
        ),
        const SizedBox(height: AppTheme.espaceSm),
        Text(
          format.montant(montant),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (sousTitre != null) ...[
          const SizedBox(height: AppTheme.espaceXs),
          Text(sousTitre!, style: const TextStyle(color: Colors.white)),
        ],
        ...pied,
      ],
    ),
  );
}
