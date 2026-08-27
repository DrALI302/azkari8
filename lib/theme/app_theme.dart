import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

class AppColors {
  // Green palette (default)
  static const primaryGreen = Color(0xFF1B5E20);
  static const primaryGreenLight = Color(0xFF2E7D32);
  static const accentGreen = Color(0xFF4CAF50);
  static const softGreen = Color(0xFFE8F5E9);

  // Blue palette
  static const primaryBlue = Color(0xFF0D47A1);
  static const accentBlue = Color(0xFF2196F3);
  static const softBlue = Color(0xFFE3F2FD);

  // Gold palette
  static const primaryGold = Color(0xFF8D6E00);
  static const accentGold = Color(0xFFD4AF37);
  static const softGold = Color(0xFFFFF8E1);

  static const gold = Color(0xFFD4AF37);
  static const darkBackground = Color(0xFF0D1F12);
  static const darkSurface = Color(0xFF152719);
  static const darkCard = Color(0xFF1E3324);
}

class _Palette {
  final Color primary;
  final Color accent;
  final Color soft;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkCard;

  const _Palette({
    required this.primary,
    required this.accent,
    required this.soft,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkCard,
  });
}

const _greenPalette = _Palette(
  primary: AppColors.primaryGreen,
  accent: AppColors.accentGreen,
  soft: AppColors.softGreen,
  darkBackground: Color(0xFF0D1F12),
  darkSurface: Color(0xFF152719),
  darkCard: Color(0xFF1E3324),
);

const _bluePalette = _Palette(
  primary: AppColors.primaryBlue,
  accent: AppColors.accentBlue,
  soft: AppColors.softBlue,
  darkBackground: Color(0xFF0A1526),
  darkSurface: Color(0xFF11213A),
  darkCard: Color(0xFF17304F),
);

const _goldPalette = _Palette(
  primary: AppColors.primaryGold,
  accent: AppColors.accentGold,
  soft: AppColors.softGold,
  darkBackground: Color(0xFF1F1808),
  darkSurface: Color(0xFF2B2210),
  darkCard: Color(0xFF3B2F16),
);

/// Returns the active palette's accent color for a given theme selection and
/// brightness — handy for widgets that need a themed accent without
/// rebuilding the whole ThemeData.
Color themeAccentColor(AppThemeColor color) => _paletteFor(color).accent;
Color themePrimaryColor(AppThemeColor color) => _paletteFor(color).primary;
Color themeSoftColor(AppThemeColor color) => _paletteFor(color).soft;
Color themeDarkCardColor(AppThemeColor color) => _paletteFor(color).darkCard;

_Palette _paletteFor(AppThemeColor color) {
  switch (color) {
    case AppThemeColor.blue:
      return _bluePalette;
    case AppThemeColor.gold:
      return _goldPalette;
    case AppThemeColor.green:
      return _greenPalette;
  }
}

class AppTheme {
  static TextTheme _arabicTextTheme(
    TextTheme base,
    double fontSize,
    FontWeight bodyWeight,
  ) {
    return base.copyWith(
      displayLarge: GoogleFonts.amiri(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.amiri(textStyle: base.displayMedium),
      displaySmall: GoogleFonts.amiri(textStyle: base.displaySmall),
      headlineLarge: GoogleFonts.amiri(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.amiri(textStyle: base.headlineMedium),
      headlineSmall: GoogleFonts.amiri(textStyle: base.headlineSmall),
      titleLarge: GoogleFonts.amiri(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.amiri(textStyle: base.titleMedium),
      titleSmall: GoogleFonts.amiri(textStyle: base.titleSmall),
      bodyLarge: GoogleFonts.amiri(
        textStyle: base.bodyLarge,
        fontSize: fontSize,
        fontWeight: bodyWeight,
        height: 1.8,
      ),
      bodyMedium: GoogleFonts.amiri(
        textStyle: base.bodyMedium,
        fontSize: fontSize - 2,
        fontWeight: bodyWeight,
        height: 1.7,
      ),
      bodySmall: GoogleFonts.amiri(textStyle: base.bodySmall),
      labelLarge: GoogleFonts.cairo(textStyle: base.labelLarge),
      labelMedium: GoogleFonts.cairo(textStyle: base.labelMedium),
      labelSmall: GoogleFonts.cairo(textStyle: base.labelSmall),
    );
  }

  static ThemeData light({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    AppThemeColor themeColor = AppThemeColor.green,
  }) {
    final palette = _paletteFor(themeColor);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
      primary: palette.primary,
      secondary: palette.accent,
      surface: Colors.white,
      surfaceContainerHighest: palette.soft,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5FAF6),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: const Color(0xFFC8E6C9),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );

    return base.copyWith(
      textTheme: _arabicTextTheme(base.textTheme, fontSize, fontWeight),
    );
  }

  static ThemeData dark({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    AppThemeColor themeColor = AppThemeColor.green,
  }) {
    final palette = _paletteFor(themeColor);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: Brightness.dark,
      primary: palette.accent,
      secondary: AppColors.gold,
      surface: palette.darkSurface,
      surfaceContainerHighest: palette.darkCard,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.darkBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.darkSurface,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accent,
        foregroundColor: palette.darkBackground,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.darkCard,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: const Color(0xFF2E4A35),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );

    return base.copyWith(
      textTheme: _arabicTextTheme(base.textTheme, fontSize, fontWeight),
    );
  }
}
