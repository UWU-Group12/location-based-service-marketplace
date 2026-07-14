import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final TextTheme _interTextTheme =
      GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
    displayLarge: ThemeData.light().textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w900,
    ),
    displayMedium: ThemeData.light().textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w900,
    ),
    displaySmall: ThemeData.light().textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w900,
    ),
    headlineLarge: ThemeData.light().textTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w900,
    ),
    headlineMedium: ThemeData.light().textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w900,
    ),
    headlineSmall: ThemeData.light().textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleLarge: ThemeData.light().textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleMedium: ThemeData.light().textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleSmall: ThemeData.light().textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: ThemeData.light().textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: ThemeData.light().textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
    ),
    bodySmall: ThemeData.light().textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w400,
    ),
    labelLarge: ThemeData.light().textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    labelMedium: ThemeData.light().textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w500,
    ),
    labelSmall: ThemeData.light().textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w500,
    ),
  );

      static ThemeData lightTheme = ThemeData(
      useMaterial3: true,

      textTheme: _interTextTheme,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.primary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
          textStyle: _interTextTheme.labelLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _interTextTheme.labelMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,

        hintStyle: const TextStyle(
          color: AppColors.hint,
          fontSize: 16,
        ),

        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.focusedBorder,
          ),
        ),
      ),
    );
}