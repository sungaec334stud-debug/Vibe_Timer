import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens ported 1:1 from the original `src/styles/variables.css`.
/// Every colour, radius and shadow below has a `--token` counterpart.
class AppColors {
  const AppColors._();

  // Surfaces (Mobile Dark OLED palette)
  static const Color bgApp = Color(0xFF090615);
  static const Color bgPhone = Color(0xFF0E0922);
  static const Color bgCard = Color(0x1A1A1230);
  static const Color bgCardElevated = Color(0xD9241A44);
  static const Color bgSheet = Color(0xFF130D2C);
  static const Color bgInput = Color(0xD90E0A1C);

  // Primary accents & glows
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleLight = Color(0xFFA78BFA);
  static const Color accentPurpleGlow = Color(0x738B5CF6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentCyanGlow = Color(0x6606B6D4);

  // Functional colours
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Text & borders
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);
  static const Color borderSubtle = Color(0x338B5CF6);
  static const Color borderActive = Color(0x998B5CF6);
}

/// Font family names declared in `pubspec.yaml`.
class AppFonts {
  const AppFonts._();

  /// --font-main
  static const String main = 'Outfit';

  /// --font-body
  static const String body = 'PlusJakartaSans';

  /// --font-mono
  static const String mono = 'JetBrainsMono';
}

class AppRadii {
  const AppRadii._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 24;
  static const double xl = 36;
  static const double full = 9999;
}

/// Text styles mirroring the CSS typography scale.
class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 51.2, // 3.2rem
    fontWeight: FontWeight.w700,
    letterSpacing: -2.05, // -0.04em
    height: 1.0,
    color: Colors.white,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: AppFonts.main,
    fontSize: 20, // 1.25rem
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: AppFonts.main,
    fontSize: 15.2, // 0.95rem
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 10.4, // 0.65rem
    fontWeight: FontWeight.w700,
    letterSpacing: 0.52,
    color: AppColors.accentPurpleLight,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 10.9, // 0.68rem
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    color: AppColors.accentPurpleLight,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12, // 0.75rem
    color: AppColors.textMuted,
    height: 1.35,
  );
}

/// Builds the app-wide dark ThemeData from the tokens above.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.accentPurple,
    onPrimary: Colors.white,
    secondary: AppColors.accentCyan,
    onSecondary: Colors.white,
    surface: AppColors.bgPhone,
    onSurface: AppColors.textPrimary,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bgPhone,
    fontFamily: AppFonts.body,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPhone,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: AppTextStyles.heading,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgSheet,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgCardElevated,
      contentTextStyle: const TextStyle(
        fontFamily: AppFonts.body,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accentPurple,
      selectionColor: AppColors.accentPurpleGlow,
      selectionHandleColor: AppColors.accentPurple,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      hintStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13.6,
        color: AppColors.textDim,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: _inputBorder(AppColors.borderSubtle),
      enabledBorder: _inputBorder(AppColors.borderSubtle),
      focusedBorder: _inputBorder(AppColors.accentPurple, width: 1.5),
    ),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.sm),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// Gradient used by the primary call-to-action buttons.
const LinearGradient kPrimaryButtonGradient = LinearGradient(
  colors: [AppColors.accentPurple, Color(0xFF7033EA)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Gradient used by the timer ring and the class-rule banner.
const LinearGradient kPurpleCyanGradient = LinearGradient(
  colors: [AppColors.accentPurple, AppColors.accentPurpleLight, AppColors.accentCyan],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);