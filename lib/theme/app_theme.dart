import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thème Material 3 de l'application (clair et sombre).
///
/// ```dart
/// MaterialApp(
///   theme: AppTheme.clair,
///   darkTheme: AppTheme.sombre,
///   themeMode: ThemeMode.system,
/// )
/// ```
///
/// Police : Inter (chiffres lisibles, montants en FCFA). L'ajouter dans
/// `pubspec.yaml` (assets `fonts/Inter-*.ttf`, famille « Inter ») ou via le
/// paquet `google_fonts`. Sans elle, la police du système est utilisée.
abstract final class AppTheme {
  static const police = 'Inter';

  // Espacements et rayons (tokens.json).
  static const espaceXs = 4.0;
  static const espaceSm = 8.0;
  static const espaceMd = 12.0;
  static const espaceLg = 16.0;
  static const espaceXl = 24.0;
  static const espaceXxl = 32.0;
  static const rayonPetit = 6.0;
  static const rayon = 8.0;
  static const rayonCarte = 12.0;
  static const rayonFeuille = 16.0;

  static final ThemeData clair = _construire(
    Brightness.light,
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaire,
      onPrimary: AppColors.surPrimaire,
      primaryContainer: AppColors.primaireTeinte,
      onPrimaryContainer: AppColors.primaireSurvol,
      secondary: AppColors.secondaire,
      onSecondary: AppColors.surSecondaire,
      secondaryContainer: AppColors.secondaireTeinte,
      onSecondaryContainer: AppColors.surSecondaire,
      tertiary: AppColors.succes,
      onTertiary: Color(0xFFFFFFFF),
      error: AppColors.danger,
      onError: Color(0xFFFFFFFF),
      errorContainer: AppColors.dangerFond,
      onErrorContainer: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.texte,
      onSurfaceVariant: AppColors.texteSecondaire,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.fond,
      surfaceContainer: AppColors.surfaceAlt,
      surfaceContainerHigh: AppColors.surfaceAlt,
      surfaceContainerHighest: AppColors.bordure,
      outline: AppColors.bordureForte,
      outlineVariant: AppColors.bordure,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.texte,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.sombrePrimaire,
    ),
    AppPalette.clair,
  );

  static final ThemeData sombre = _construire(
    Brightness.dark,
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.sombrePrimaire,
      onPrimary: AppColors.sombreSurPrimaire,
      primaryContainer: AppColors.sombrePrimaireTeinte,
      onPrimaryContainer: AppColors.sombreTexte,
      secondary: AppColors.secondaire,
      onSecondary: AppColors.surSecondaire,
      secondaryContainer: AppColors.sombreSecondaireTeinte,
      onSecondaryContainer: AppColors.secondaire,
      tertiary: AppColors.sombreSucces,
      onTertiary: AppColors.sombreFond,
      error: AppColors.sombreDanger,
      onError: AppColors.sombreFond,
      errorContainer: AppColors.sombreDangerFond,
      onErrorContainer: AppColors.sombreDanger,
      surface: AppColors.sombreSurface,
      onSurface: AppColors.sombreTexte,
      onSurfaceVariant: AppColors.sombreTexteSecondaire,
      surfaceContainerLowest: AppColors.sombreFond,
      surfaceContainerLow: AppColors.sombreFond,
      surfaceContainer: AppColors.sombreSurface,
      surfaceContainerHigh: AppColors.sombreSurfaceAlt,
      surfaceContainerHighest: AppColors.sombreBordure,
      outline: AppColors.sombreBordureForte,
      outlineVariant: AppColors.sombreBordure,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.sombreTexte,
      onInverseSurface: AppColors.sombreFond,
      inversePrimary: AppColors.primaire,
    ),
    AppPalette.sombre,
  );

  static ThemeData _construire(Brightness luminosite, ColorScheme cs, AppPalette p) {
    final base = ThemeData(useMaterial3: true, brightness: luminosite, colorScheme: cs, fontFamily: police);
    final texte = base.textTheme.apply(bodyColor: p.texte, displayColor: p.texte);
    final rayonControle = BorderRadius.circular(rayon);

    return base.copyWith(
      scaffoldBackgroundColor: p.fond,
      extensions: [p],
      textTheme: texte.copyWith(
        headlineMedium: texte.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
        titleLarge: texte.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: texte.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: texte.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: texte.bodyMedium?.copyWith(fontSize: 14, color: p.texteSecondaire),
        labelLarge: texte.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        bodySmall: texte.bodySmall?.copyWith(fontSize: 12, color: p.texteSecondaire),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: luminosite == Brightness.light ? cs.primary : cs.surface,
        foregroundColor: luminosite == Brightness.light ? cs.onPrimary : cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rayonCarte), side: BorderSide(color: p.bordure)),
      ),
      // Bouton principal (UN par écran) : bleu.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      // Bouton secondaire : contour bleu.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: cs.primary)),
      // Action mise en avant (« Ajouter un bien ») : or, texte foncé.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.secondary,
        foregroundColor: cs.onSecondary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: espaceLg, vertical: espaceMd),
        border: OutlineInputBorder(borderRadius: rayonControle, borderSide: BorderSide(color: p.bordureChamp)),
        enabledBorder: OutlineInputBorder(borderRadius: rayonControle, borderSide: BorderSide(color: p.bordureChamp)),
        focusedBorder: OutlineInputBorder(borderRadius: rayonControle, borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: rayonControle, borderSide: BorderSide(color: cs.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: rayonControle, borderSide: BorderSide(color: cs.error, width: 2)),
        labelStyle: TextStyle(color: p.texteSecondaire),
        hintStyle: TextStyle(color: p.texteDiscret),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.primaireTeinte,
        side: BorderSide(color: p.bordure),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: p.primaireTeinte,
        iconTheme: WidgetStateProperty.resolveWith(
          (etats) => IconThemeData(color: etats.contains(WidgetState.selected) ? cs.primary : p.texteSecondaire),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (etats) => TextStyle(
            fontSize: 12,
            fontWeight: etats.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: etats.contains(WidgetState.selected) ? cs.primary : p.texteSecondaire,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.bordure, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: rayonControle),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
    );
  }
}
