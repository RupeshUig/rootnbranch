import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Reusable light Material 3 theme and typography system for Root N Branch Men's Salon.
class AppTheme {
  AppTheme._();

  // Centralized typography scale — Plus Jakarta Sans
  static TextStyle get screenHeading => GoogleFonts.plusJakartaSans(
    color: AppColors.primaryText,
    fontSize: 27,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle get sectionHeading => GoogleFonts.plusJakartaSans(
    color: AppColors.primaryText,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    color: AppColors.primaryText,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    color: AppColors.secondaryText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
    color: AppColors.secondaryText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static TextStyle get fieldLabel => GoogleFonts.plusJakartaSans(
    color: AppColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get inputText => GoogleFonts.plusJakartaSans(
    color: AppColors.primaryText,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle get linkText => GoogleFonts.plusJakartaSans(
    color: AppColors.primaryPurple,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get helperText => GoogleFonts.plusJakartaSans(
    color: AppColors.secondaryText,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static TextStyle get errorText => GoogleFonts.plusJakartaSans(
    color: AppColors.error,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryPurple,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.lightLavender,
      onPrimaryContainer: AppColors.darkPurple,
      secondary: AppColors.darkPurple,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.lightPink,
      onSecondaryContainer: AppColors.darkPink,
      tertiary: AppColors.darkPink,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.primaryText,
      outline: AppColors.subtleBorder,
      outlineVariant: AppColors.lightLavender,
    );

    final baseTextTheme = ThemeData.light().textTheme;
    final plusJakartaTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme)
        .copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryText,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineLarge: screenHeading,
          headlineMedium: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: sectionHeading,
          titleMedium: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: helperText,
          labelLarge: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: errorText,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.softBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.softBackground,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          textStyle: linkText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.secondaryText.withValues(alpha: 0.65),
          fontWeight: FontWeight.w400,
        ),
        errorStyle: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.subtleBorder,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.subtleBorder,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryPurple,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),
      textTheme: plusJakartaTheme,
    );
  }
}
