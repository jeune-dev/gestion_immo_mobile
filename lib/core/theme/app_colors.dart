import 'package:flutter/material.dart';

/// Couleurs de la charte Gestion Immobilière — palette « Bleu confiance et or ».
///
/// Valeurs reprises de `charte-graphique/tokens.json` (source unique) : ne pas
/// modifier une couleur ici sans la modifier là-bas (et côté back-office).
///
/// Dans les écrans, préférer `Theme.of(context).colorScheme` et l'extension
/// [AppPalette] (`context.palette`) : elles basculent seules en mode sombre.
abstract final class AppColors {
  // ── Marque ────────────────────────────────────────────────────────────────
  static const primaire = Color(0xFF1D4E89);
  static const primaireSurvol = Color(0xFF173F70);
  static const primaireTeinte = Color(0xFFE8F0FA);
  static const surPrimaire = Color(0xFFFFFFFF);

  static const secondaire = Color(0xFFF4A93B);
  static const secondaireSurvol = Color(0xFFE0952A);
  static const secondaireTeinte = Color(0xFFFEF3E2);

  /// Texte sur l'or : TOUJOURS foncé, jamais blanc (contraste insuffisant).
  static const surSecondaire = Color(0xFF3A2604);

  // ── Neutres (mode clair) ──────────────────────────────────────────────────
  static const fond = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F3F6);
  static const bordure = Color(0xFFE2E6EC);
  static const bordureForte = Color(0xFFCBD2DB);

  /// Contour des champs de saisie (contraste ≥ 3:1, repérable par tous).
  static const bordureChamp = Color(0xFF848E9D);
  static const texte = Color(0xFF1F2937);
  static const texteSecondaire = Color(0xFF6B7280);
  static const texteDiscret = Color(0xFF9CA3AF);

  // ── États (mode clair) ────────────────────────────────────────────────────
  static const succes = Color(0xFF18763A);
  static const succesFond = Color(0xFFE6F4EA);
  static const avertissement = Color(0xFFB45309);
  static const avertissementFond = Color(0xFFFFF4E5);
  static const danger = Color(0xFFC62828);
  static const dangerFond = Color(0xFFFDECEC);
  static const info = Color(0xFF1D4E89);
  static const infoFond = Color(0xFFE8F0FA);
  static const neutre = Color(0xFF4B5563);
  static const neutreFond = Color(0xFFF1F3F6);

  // ── Mode sombre ───────────────────────────────────────────────────────────
  static const sombrePrimaire = Color(0xFF6FA8E8);
  static const sombrePrimaireSurvol = Color(0xFF8BBBEE);
  static const sombrePrimaireTeinte = Color(0xFF17304F);
  static const sombreSurPrimaire = Color(0xFF0B2440);
  static const sombreSecondaireSurvol = Color(0xFFF7BC63);
  static const sombreSecondaireTeinte = Color(0xFF3A2A12);
  static const sombreFond = Color(0xFF0E1621);
  static const sombreSurface = Color(0xFF16202D);
  static const sombreSurfaceAlt = Color(0xFF1E2A3A);
  static const sombreBordure = Color(0xFF2A3747);
  static const sombreBordureForte = Color(0xFF3A4A5E);
  static const sombreBordureChamp = Color(0xFF66778C);
  static const sombreTexte = Color(0xFFE6EAF0);
  static const sombreTexteSecondaire = Color(0xFFA3AEBD);
  static const sombreTexteDiscret = Color(0xFF6B7686);
  static const sombreSucces = Color(0xFF4CC27A);
  static const sombreSuccesFond = Color(0xFF133222);
  static const sombreAvertissement = Color(0xFFFB923C);
  static const sombreAvertissementFond = Color(0xFF3A2412);
  static const sombreDanger = Color(0xFFF87171);
  static const sombreDangerFond = Color(0xFF3B1717);
  static const sombreNeutre = Color(0xFFA3AEBD);
  static const sombreNeutreFond = Color(0xFF1E2A3A);
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
  /// Couleurs de la charte pour le mode (clair / sombre) en cours.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
