import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';

/// Picto TerangaLoc : une maison, carrée, en deux versions.
///
/// Sur un fond clair, la tuile bleu nuit (`picto_terangaloc.png`). Sur l'en-tête
/// ou une barre marine, [clair] prend la version sans tuile
/// (`picto_terangaloc_clair.png`) : maison blanche et porte verte sur fond
/// transparent. La tuile marine posée sur du marine ne se verrait pas.
class LogoTerangaLoc extends StatelessWidget {
  final double largeur;

  /// Version claire, pour les fonds foncés.
  final bool clair;
  const LogoTerangaLoc({super.key, this.largeur = 48, this.clair = false});

  static const asset = 'assets/images/picto_terangaloc.png';
  static const assetClair = 'assets/images/picto_terangaloc_clair.png';

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'TerangaLoc',
    image: true,
    child: Image.asset(
      clair ? assetClair : asset,
      width: largeur,
      // Le picto est carré ; la hauteur est réservée pour que la mise en page
      // ne bouge pas pendant le chargement.
      height: largeur,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    ),
  );
}

/// Picto en haut à gauche de la barre des écrans racines (onglets). Sur un
/// écran empilé, renvoie `null` : la barre garde son bouton retour.
class LogoBarre extends StatelessWidget {
  /// Marge gauche (dans une barre d'application) ; aucune dans un en-tête.
  final bool marge;
  const LogoBarre({super.key, this.marge = true});

  static const largeur = 56.0;

  static Widget? siRacine(BuildContext context) =>
      (ModalRoute.of(context)?.canPop ?? false) ? null : const LogoBarre();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: marge ? 14 : 0),
    child: const Align(
      alignment: Alignment.centerLeft,
      child: LogoTerangaLoc(largeur: 32, clair: true),
    ),
  );
}

/// Nom de la marque : « Teranga » en bleu nuit, « Loc » en vert.
class NomTerangaLoc extends StatelessWidget {
  final double taille;

  /// Sur fond marine : « Teranga » en blanc et « Loc » en vert clair.
  final bool surFonce;
  const NomTerangaLoc({super.key, this.taille = 22, this.surFonce = false});

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'Teranga',
          style: TextStyle(color: surFonce ? Colors.white : AppColors.marine),
        ),
        TextSpan(
          text: 'Loc',
          style: TextStyle(
            color: surFonce ? AppColors.vertLogo : AppColors.secondaire,
          ),
        ),
      ],
    ),
    style: TextStyle(
      fontSize: taille,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
  );
}
