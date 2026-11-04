import 'package:flutter/material.dart';

/// Palette tirée du logo Kërimmo : dégradé de bleus (nuit → roi → ciel),
/// vert « immo » (foncé → citron) et blanc. Rouge et orange restent réservés
/// aux erreurs et aux alertes.
///
/// Dans les écrans, préférer `Theme.of(context).colorScheme` et l'extension
/// [AppPalette] (`context.palette`) : elles basculent seules en mode sombre.
abstract final class AppColors {
  // ── Marque ────────────────────────────────────────────────────────────────
  /// Bleu nuit du mot « Kër » et des ombres du logo.
  static const marine = Color(0xFF0B2A5B);
  static const primaire = Color(0xFF0E56B0);
  static const primaireSurvol = Color(0xFF0A4590);
  static const primaireTeinte = Color(0xFFE6F0FC);
  static const surPrimaire = Color(0xFFFFFFFF);

  static const secondaire = Color(0xFF2E9E1F);
  static const secondaireSurvol = Color(0xFF23850F);
  static const secondaireTeinte = Color(0xFFE8F6E2);

  /// Bleu ciel des immeubles du logo (dégradés, accents).
  static const bleuLogo = Color(0xFF1E88E5);

  /// Vert citron de l'arc du logo (accents sur fond bleu).
  static const vertLogo = Color(0xFF7CC42A);

  /// Texte sur le vert : blanc, en gras.
  static const surSecondaire = Color(0xFFFFFFFF);

  // ── Dégradés de marque ────────────────────────────────────────────────────
  /// En-têtes et barres : bleu nuit → bleu roi → bleu ciel, de gauche à droite
  /// (horizontal : deux bandeaux de hauteurs différentes se raccordent sans
  /// couture).
  static const degradeMarque = LinearGradient(
    colors: [marine, primaire, bleuLogo],
    stops: [0, 0.55, 1],
  );

  /// Variante du mode sombre : mêmes teintes, assourdies.
  static const degradeMarqueSombre = LinearGradient(
    colors: [Color(0xFF061730), Color(0xFF0A346E), Color(0xFF0F4E94)],
    stops: [0, 0.55, 1],
  );

  /// Vert du logo, foncé → citron (accents, jauges, pastilles).
  static const degradeVert = LinearGradient(
    colors: [secondaireSurvol, secondaire, vertLogo],
    stops: [0, 0.5, 1],
  );

  // ── Neutres (mode clair) ──────────────────────────────────────────────────
  static const fond = Color(0xFFF3F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEEF3FA);
  static const bordure = Color(0xFFE2E9F2);
  static const bordureForte = Color(0xFFC9D4E3);

  /// Contour des champs de saisie (contraste ≥ 3:1, repérable par tous).
  static const bordureChamp = Color(0xFF8493A8);
  static const texte = Color(0xFF0D1B33);
  static const texteSecondaire = Color(0xFF5A6A82);
  static const texteDiscret = Color(0xFF94A1B5);

  // ── États (mode clair) ────────────────────────────────────────────────────
  static const succes = Color(0xFF1F7A12);
  static const succesFond = Color(0xFFE8F6E2);
  static const avertissement = Color(0xFFB45309);
  static const avertissementFond = Color(0xFFFFF4E5);
  static const danger = Color(0xFFC62828);
  static const dangerFond = Color(0xFFFDECEC);
  static const info = Color(0xFF0E56B0);
  static const infoFond = Color(0xFFE6F0FC);
  static const neutre = Color(0xFF4B5B70);
  static const neutreFond = Color(0xFFF0F3F8);

  // ── Mode sombre ───────────────────────────────────────────────────────────
  static const sombrePrimaire = Color(0xFF64A8F2);
  static const sombrePrimaireSurvol = Color(0xFF8DBFF5);
  static const sombrePrimaireTeinte = Color(0xFF132E52);
  static const sombreSurPrimaire = Color(0xFF06203F);
  static const sombreSecondaireSurvol = Color(0xFF8BD35A);
  static const sombreSecondaireTeinte = Color(0xFF15301A);
  static const sombreFond = Color(0xFF07111F);
  static const sombreSurface = Color(0xFF0F1C2E);
  static const sombreSurfaceAlt = Color(0xFF16263D);
  static const sombreBordure = Color(0xFF223450);
  static const sombreBordureForte = Color(0xFF33496A);
  static const sombreBordureChamp = Color(0xFF627896);
  static const sombreTexte = Color(0xFFE7EDF5);
  static const sombreTexteSecondaire = Color(0xFFA2B0C4);
  static const sombreTexteDiscret = Color(0xFF6B7A90);
  static const sombreSucces = Color(0xFF7CC94F);
  static const sombreSuccesFond = Color(0xFF15301A);
  static const sombreAvertissement = Color(0xFFFB923C);
  static const sombreAvertissementFond = Color(0xFF3A2412);
  static const sombreDanger = Color(0xFFF87171);
  static const sombreDangerFond = Color(0xFF3B1717);
  static const sombreNeutre = Color(0xFFA2B0C4);
  static const sombreNeutreFond = Color(0xFF16263D);
}

/// Couleurs hors `ColorScheme` (états, textes secondaires, bordures), en clair
/// et en sombre. Accès : `context.palette.succes`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color fond;
  final Color surfaceAlt;
  final Color bordure;
  final Color bordureForte;
  final Color bordureChamp;
  final Color texte;
  final Color texteSecondaire;
  final Color texteDiscret;
  final Color primaireTeinte;
  final Color secondaireTeinte;
  final Color succes;
  final Color succesFond;
  final Color avertissement;
  final Color avertissementFond;
  final Color danger;
  final Color dangerFond;
  final Color info;
  final Color infoFond;
  final Color neutre;
  final Color neutreFond;

  const AppPalette({
    required this.fond,
    required this.surfaceAlt,
    required this.bordure,
    required this.bordureForte,
    required this.bordureChamp,
    required this.texte,
    required this.texteSecondaire,
    required this.texteDiscret,
    required this.primaireTeinte,
    required this.secondaireTeinte,
    required this.succes,
    required this.succesFond,
    required this.avertissement,
    required this.avertissementFond,
    required this.danger,
    required this.dangerFond,
    required this.info,
    required this.infoFond,
    required this.neutre,
    required this.neutreFond,
  });

  static const clair = AppPalette(
    fond: AppColors.fond,
    surfaceAlt: AppColors.surfaceAlt,
    bordure: AppColors.bordure,
    bordureForte: AppColors.bordureForte,
    bordureChamp: AppColors.bordureChamp,
    texte: AppColors.texte,
    texteSecondaire: AppColors.texteSecondaire,
    texteDiscret: AppColors.texteDiscret,
    primaireTeinte: AppColors.primaireTeinte,
    secondaireTeinte: AppColors.secondaireTeinte,
    succes: AppColors.succes,
    succesFond: AppColors.succesFond,
    avertissement: AppColors.avertissement,
    avertissementFond: AppColors.avertissementFond,
    danger: AppColors.danger,
    dangerFond: AppColors.dangerFond,
    info: AppColors.info,
    infoFond: AppColors.infoFond,
    neutre: AppColors.neutre,
    neutreFond: AppColors.neutreFond,
  );

  static const sombre = AppPalette(
    fond: AppColors.sombreFond,
    surfaceAlt: AppColors.sombreSurfaceAlt,
    bordure: AppColors.sombreBordure,
    bordureForte: AppColors.sombreBordureForte,
    bordureChamp: AppColors.sombreBordureChamp,
    texte: AppColors.sombreTexte,
    texteSecondaire: AppColors.sombreTexteSecondaire,
    texteDiscret: AppColors.sombreTexteDiscret,
    primaireTeinte: AppColors.sombrePrimaireTeinte,
    secondaireTeinte: AppColors.sombreSecondaireTeinte,
    succes: AppColors.sombreSucces,
    succesFond: AppColors.sombreSuccesFond,
    avertissement: AppColors.sombreAvertissement,
    avertissementFond: AppColors.sombreAvertissementFond,
    danger: AppColors.sombreDanger,
    dangerFond: AppColors.sombreDangerFond,
    info: AppColors.sombrePrimaire,
    infoFond: AppColors.sombrePrimaireTeinte,
    neutre: AppColors.sombreNeutre,
    neutreFond: AppColors.sombreNeutreFond,
  );

  @override
  AppPalette copyWith({
    Color? fond,
    Color? surfaceAlt,
    Color? bordure,
    Color? bordureForte,
    Color? bordureChamp,
    Color? texte,
    Color? texteSecondaire,
    Color? texteDiscret,
    Color? primaireTeinte,
    Color? secondaireTeinte,
    Color? succes,
    Color? succesFond,
    Color? avertissement,
    Color? avertissementFond,
    Color? danger,
    Color? dangerFond,
    Color? info,
    Color? infoFond,
    Color? neutre,
    Color? neutreFond,
  }) {
    return AppPalette(
      fond: fond ?? this.fond,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      bordure: bordure ?? this.bordure,
      bordureForte: bordureForte ?? this.bordureForte,
      bordureChamp: bordureChamp ?? this.bordureChamp,
      texte: texte ?? this.texte,
      texteSecondaire: texteSecondaire ?? this.texteSecondaire,
      texteDiscret: texteDiscret ?? this.texteDiscret,
      primaireTeinte: primaireTeinte ?? this.primaireTeinte,
      secondaireTeinte: secondaireTeinte ?? this.secondaireTeinte,
      succes: succes ?? this.succes,
      succesFond: succesFond ?? this.succesFond,
      avertissement: avertissement ?? this.avertissement,
      avertissementFond: avertissementFond ?? this.avertissementFond,
      danger: danger ?? this.danger,
      dangerFond: dangerFond ?? this.dangerFond,
      info: info ?? this.info,
      infoFond: infoFond ?? this.infoFond,
      neutre: neutre ?? this.neutre,
      neutreFond: neutreFond ?? this.neutreFond,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      fond: m(fond, other.fond),
      surfaceAlt: m(surfaceAlt, other.surfaceAlt),
      bordure: m(bordure, other.bordure),
      bordureForte: m(bordureForte, other.bordureForte),
      bordureChamp: m(bordureChamp, other.bordureChamp),
      texte: m(texte, other.texte),
      texteSecondaire: m(texteSecondaire, other.texteSecondaire),
      texteDiscret: m(texteDiscret, other.texteDiscret),
      primaireTeinte: m(primaireTeinte, other.primaireTeinte),
      secondaireTeinte: m(secondaireTeinte, other.secondaireTeinte),
      succes: m(succes, other.succes),
      succesFond: m(succesFond, other.succesFond),
      avertissement: m(avertissement, other.avertissement),
      avertissementFond: m(avertissementFond, other.avertissementFond),
      danger: m(danger, other.danger),
      dangerFond: m(dangerFond, other.dangerFond),
      info: m(info, other.info),
      infoFond: m(infoFond, other.infoFond),
      neutre: m(neutre, other.neutre),
      neutreFond: m(neutreFond, other.neutreFond),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Couleurs de la charte pour le mode (clair / sombre) en cours. Sous un
  /// thème qui ne la déclare pas (tests, `Theme` local), la palette du mode
  /// en cours sert de repli au lieu d'une exception.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalette.sombre
            : AppPalette.clair);
  }
}
