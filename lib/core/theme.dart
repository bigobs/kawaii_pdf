import 'package:flutter/material.dart';

/// Tema Kawaii de la aplicación mipdf.
///
/// Paleta basada en la regla 70/20/10 rosa:
/// - 70% neutros rosados (crema, blush, blanco cálido)
/// - 20% rosas medios
/// - 10% acento vibrante (coral, fucsia)
class AppTheme {
  AppTheme._();

  // ── Neutros cálidos ──────────────────────────────────────────────
  static const Color cream = Color(0xFFFFF9F7);
  static const Color blush = Color(0xFFFFEFF3);

  // ── Escala rosa ──────────────────────────────────────────────────
  static const Color pink50 = Color(0xFFFFF0F5);
  static const Color pink100 = Color(0xFFFFE0EB);
  static const Color pink200 = Color(0xFFFFC2D7);
  static const Color pink300 = Color(0xFFFFA3C1);
  static const Color pink400 = Color(0xFFFF85A8);
  static const Color pink500 = Color(0xFFFF6B9D);
  static const Color pink600 = Color(0xFFE84A7F);
  static const Color pink700 = Color(0xFFC42F63);

  // ── Acentos secundarios ──────────────────────────────────────────
  static const Color lavender = Color(0xFFE5D4FF);
  static const Color peach = Color(0xFFFFD4C2);
  static const Color coral = Color(0xFFFF9A8B);
  static const Color mint = Color(0xFFC8F0E0);

  // ── Texto ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF4A2C3A);
  static const Color textSecondary = Color(0xFF8A6B78);
  static const Color textMuted = Color(0xFFB8A0A9);

  // ── Degradados ───────────────────────────────────────────────────
  static const List<Color> gradHero = [Color(0xFFFFE0EB), Color(0xFFFF85A8)];
  static const List<Color> gradButton = [Color(0xFFFF9DBE), Color(0xFFFF6B9D)];
  static const List<Color> gradCard = [Color(0xFFFFF9F7), Color(0xFFFFE0EB)];
  static const List<Color> gradDreamy = [Color(0xFFFFC2D7), Color(0xFFE5D4FF)];

  /// Sombra kawaii estándar para cards.
  static List<BoxShadow> get kawaiiShadow => [
        BoxShadow(
          color: const Color(0xFFFF6B9D).withValues(alpha: 0.18),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Sombra kawaii sutil para botones.
  static List<BoxShadow> get kawaiiShadowLight => [
        BoxShadow(
          color: const Color(0xFFFF6B9D).withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Tema ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pink500,
        brightness: Brightness.light,
        primary: pink500,
        onPrimary: Colors.white,
        secondary: pink300,
        surface: cream,
        error: coral,
      ),
      scaffoldBackgroundColor: cream,

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: pink500,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink500,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pink600,
          side: const BorderSide(color: pink300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pink200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pink200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pink500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: coral, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        prefixIconColor: pink400,
      ),

      // Textos globales
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }
}
