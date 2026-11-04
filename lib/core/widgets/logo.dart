import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';

/// Pictogramme Kërimmo : maison et immeubles enlacés d'un arc vert, tiré du
/// logo officiel (`assets/images/picto_kerimmo.png`, fond transparent).
/// Plus large que haut (≈ 2,5 : 1) : on le dimensionne par sa [largeur].
class LogoKerimmo extends StatelessWidget {
  final double largeur;
  const LogoKerimmo({super.key, this.largeur = 48});

  static const asset = 'assets/images/picto_kerimmo.png';

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Kërimmo',
    image: true,
    child: Image.asset(
      asset,
      width: largeur,
      // Hauteur réservée : la pastille garde sa taille pendant le chargement.
      height: largeur / 2.5,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    ),
  );
}

/// Pictogramme en haut à gauche de la barre des écrans racines (onglets),
/// comme dans Yobante. Sur un écran empilé, renvoie `null` : la barre garde
/// son bouton retour.
class LogoBarre extends StatelessWidget {
  /// Marge gauche (dans une barre d'application) ; aucune dans un en-tête.
  final bool marge;
  const LogoBarre({super.key, this.marge = true});

  static const largeur = 84.0;

  static Widget? siRacine(BuildContext context) =>
      (ModalRoute.of(context)?.canPop ?? false) ? null : const LogoBarre();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: marge ? 16 : 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33061730),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const LogoKerimmo(largeur: 58),
      ),
    ),
  );
}

/// Nom de la marque : « Kër » en bleu, « immo » en vert.
class NomKerimmo extends StatelessWidget {
  final double taille;

  /// Sur fond bleu : « Kër » en blanc.
  final bool surFonce;
  const NomKerimmo({super.key, this.taille = 22, this.surFonce = false});

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'Kër',
          style: TextStyle(color: surFonce ? Colors.white : AppColors.marine),
        ),
        TextSpan(
          text: 'immo',
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
