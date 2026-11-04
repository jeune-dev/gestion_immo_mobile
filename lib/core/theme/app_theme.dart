import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const rayonPetit = 10.0;
  static const rayon = 14.0;
  static const rayonCarte = 20.0;
  static const rayonFeuille = 28.0;

  /// Ombre douce des cartes (mode clair), teintée du bleu nuit du logo.
  static const ombreCarte = [
    BoxShadow(color: Color(0x140B2A5B), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A0B2A5B), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// Couleur unie de repli des en-têtes ; le rendu final est le dégradé
  /// [AppColors.degradeMarque] posé par `FondMarque`.
  static const bleuEnTete = AppColors.marine;

  /// Durée et courbe des animations de l'interface (fluides, sans lenteur).
  static const duree = Duration(milliseconds: 280);
  static const courbe = Curves.easeOutCubic;

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
      onSecondaryContainer: AppColors.secondaireSurvol,
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
      secondary: AppColors.vertLogo,
      onSecondary: AppColors.sombreFond,
      secondaryContainer: AppColors.sombreSecondaireTeinte,
      onSecondaryContainer: AppColors.sombreSecondaireSurvol,
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

  static ThemeData _construire(
    Brightness luminosite,
    ColorScheme cs,
    AppPalette p,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: luminosite,
      colorScheme: cs,
      fontFamily: police,
    );
    final texte = base.textTheme.apply(
      bodyColor: p.texte,
      displayColor: p.texte,
    );
    final rayonControle = BorderRadius.circular(rayon);
    final clair = luminosite == Brightness.light;

    return base.copyWith(
      scaffoldBackgroundColor: p.fond,
      extensions: [p],
      // Transitions : glissé iOS, fondu-avancé Android (fluide, sans saut).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: texte.copyWith(
        headlineMedium: texte.headlineMedium?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleLarge: texte.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: texte.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        bodyLarge: texte.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: texte.bodyMedium?.copyWith(
          fontSize: 14,
          color: p.texteSecondaire,
        ),
        labelLarge: texte.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: texte.bodySmall?.copyWith(
          fontSize: 12,
          color: p.texteSecondaire,
        ),
      ),
      // Barre du haut au dégradé du logo (posé par `FondMarque` dans
      // `flexibleSpace`) ; titre et icônes blancs, dans les deux modes.
      appBarTheme: AppBarTheme(
        backgroundColor: clair ? bleuEnTete : const Color(0xFF061730),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: police,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
      ),
      // Onglets (toujours sous la barre bleue) : blanc, trait vert citron arrondi.
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.68),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.vertLogo, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.08),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: police,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: police,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      // Cartes blanches, ombre douce bleu nuit, sur le fond bleuté très clair.
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: clair ? 1.5 : 0,
        shadowColor: const Color(0x400B2A5B),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rayonCarte),
          side: clair ? BorderSide.none : BorderSide(color: p.bordure),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rayonFeuille),
        ),
        titleTextStyle: TextStyle(
          fontFamily: police,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: p.texte,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.bordureForte,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(rayonFeuille),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: rayonControle),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: espaceLg),
        shape: RoundedRectangleBorder(borderRadius: rayonControle),
        titleTextStyle: TextStyle(
          fontFamily: police,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: p.texte,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: police,
          fontSize: 13,
          color: p.texteSecondaire,
        ),
      ),
      // Bouton principal (UN par écran) : vert du logo, texte blanc.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondaireSurvol,
          foregroundColor: Colors.white,
          disabledBackgroundColor: clair ? p.bordure : p.surfaceAlt,
          minimumSize: const Size(64, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
          textStyle: const TextStyle(
            fontFamily: police,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      // Bouton secondaire : contour discret.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          backgroundColor: cs.surface,
          side: BorderSide(color: p.bordureForte),
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
          textStyle: const TextStyle(
            fontFamily: police,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: const TextStyle(
            fontFamily: police,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Action mise en avant (« Ajouter un bien ») : vert, texte blanc.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 48),
        extendedPadding: const EdgeInsets.symmetric(horizontal: espaceLg),
        extendedIconLabelSpacing: espaceSm,
        backgroundColor: AppColors.secondaireSurvol,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: const TextStyle(
          fontFamily: police,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      // Champs teintés de bleu très clair ; contour bleu roi au focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: clair ? const Color(0xFFF7FAFE) : p.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: espaceLg + 2,
          vertical: espaceLg,
        ),
        border: OutlineInputBorder(
          borderRadius: rayonControle,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: rayonControle,
          borderSide: BorderSide(
            color: clair ? p.bordureForte : p.bordureChamp,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: rayonControle,
          borderSide: BorderSide(color: cs.primary, width: 1.8),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (etats) => TextStyle(
            color: etats.contains(WidgetState.error)
                ? cs.error
                : etats.contains(WidgetState.focused)
                ? cs.primary
                : p.texteSecondaire,
            fontWeight: FontWeight.w500,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: rayonControle,
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: rayonControle,
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: TextStyle(color: p.texteSecondaire),
        hintStyle: TextStyle(color: p.texteDiscret),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cs.surface,
        // Sélection en vert clair, texte vert foncé (onSecondaryContainer).
        selectedColor: p.secondaireTeinte,
        checkmarkColor: cs.onSecondaryContainer,
        side: BorderSide(color: p.bordure),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      // Barre d'onglets blanche, ombre portée vers le haut, pastille bleu clair.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x330B2A5B),
        height: 70,
        indicatorColor: p.primaireTeinte,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (etats) => IconThemeData(
            color: etats.contains(WidgetState.selected)
                ? cs.primary
                : p.texteSecondaire,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (etats) => TextStyle(
            fontSize: 12,
            fontWeight: etats.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: etats.contains(WidgetState.selected)
                ? cs.primary
                : p.texteSecondaire,
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
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: p.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (etats) => etats.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (etats) => etats.contains(WidgetState.selected)
              ? AppColors.secondaire
              : null,
        ),
      ),
    );
  }
}
