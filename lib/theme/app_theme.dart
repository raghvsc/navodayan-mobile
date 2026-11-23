import 'package:flutter/material.dart';

class ThemePalette {
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDark;
  final Color border;
  final Color error;
  final Color errorBg;
  final Color success;
  final Color successBg;
  final Color badgeBg;
  final Color badgeText;
  final LinearGradient brandGradient;
  final LinearGradient goldGradient;

  const ThemePalette({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDark,
    required this.border,
    required this.error,
    required this.errorBg,
    required this.success,
    required this.successBg,
    required this.badgeBg,
    required this.badgeText,
    required this.brandGradient,
    required this.goldGradient,
  });
}

class AppColors {
  // Static Light Tokens harmonized with Navodaya Alumni Connect Design System
  static const Color primary = Color(0xFF0F294A); // Primary Navy (#0F294A / #0B2545)
  static const Color primaryLight = Color(0xFF1E3A8A); // Tertiary Deep Indigo
  static const Color secondary = Color(0xFFD97706); // Warm Ochre / Saffron Gold (#D97706)
  static const Color accent = Color(0xFFEA580C); // Sunrise Amber

  static const Color background = Color(0xFFF8FAFC); // Canvas Base Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Card & Sheet Surface Pure White
  static const Color cardBg = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A); // Neutral Slate-Black
  static const Color textSecondary = Color(0xFF64748B); // Slate Muted
  static const Color textDark = Color(0xFF1E293B);

  static const Color border = Color(0xFFE2E8F0); // Border Subtle Slate 200
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);

  static const Color badgeBg = Color(0xFFFEF3C7);
  static const Color badgeText = Color(0xFFB45309);

  // JNV House Colors
  static const Color aravaliText = Color(0xFF1D4ED8);
  static const Color aravaliBg = Color(0xFFEFF6FF);
  static const Color aravaliBorder = Color(0xFFBFDBFE);

  static const Color nilgiriText = Color(0xFF15803D);
  static const Color nilgiriBg = Color(0xFFF0FDF4);
  static const Color nilgiriBorder = Color(0xFFBBF7D0);

  static const Color shivalikText = Color(0xFFB91C1C);
  static const Color shivalikBg = Color(0xFFFEF2F2);
  static const Color shivalikBorder = Color(0xFFFECACA);

  static const Color udaygiriText = Color(0xFFB45309);
  static const Color udaygiriBg = Color(0xFFFFFBEB);
  static const Color udaygiriBorder = Color(0xFFFDE68A);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0B2545), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic Theme-Aware Palette Accessor
  static ThemePalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const ThemePalette(
        primary: Color(0xFF60A5FA), // Crisp high-contrast blue for dark surfaces
        primaryLight: Color(0xFF93C5FD),
        secondary: Color(0xFFFBBF24), // Saffron gold
        accent: Color(0xFFFB923C), // Amber
        background: Color(0xFF0B1120), // Deep Midnight Navy/Slate
        surface: Color(0xFF1E293B), // Elevated Slate 800
        cardBg: Color(0xFF1E293B),
        textPrimary: Color(0xFFF8FAFC), // Pure readable slate-white
        textSecondary: Color(0xFF94A3B8), // Muted slate
        textDark: Color(0xFFE2E8F0),
        border: Color(0xFF334155), // Slate 700 border
        error: Color(0xFFF87171),
        errorBg: Color(0xFF450A0A),
        success: Color(0xFF4ADE80),
        successBg: Color(0xFF052E16),
        badgeBg: Color(0xFF78350F),
        badgeText: Color(0xFFFDE68A),
        brandGradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        goldGradient: LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFF9A3412)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    return const ThemePalette(
      primary: Color(0xFF0F294A), // Primary Navy (#0F294A / #0B2545)
      primaryLight: Color(0xFF1E3A8A),
      secondary: Color(0xFFD97706), // Warm Saffron / Amber Gold
      accent: Color(0xFFEA580C), // Sunrise Amber
      background: Color(0xFFF8FAFC), // Pure off-white
      surface: Color(0xFFFFFFFF),
      cardBg: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF0F172A), // Dark slate
      textSecondary: Color(0xFF64748B),
      textDark: Color(0xFF1E293B),
      border: Color(0xFFE2E8F0),
      error: Color(0xFFDC2626),
      errorBg: Color(0xFFFEF2F2),
      success: Color(0xFF16A34A),
      successBg: Color(0xFFF0FDF4),
      badgeBg: Color(0xFFFEF3C7),
      badgeText: Color(0xFFB45309),
      brandGradient: LinearGradient(
        colors: [Color(0xFF0B2545), Color(0xFF0F294A), Color(0xFF1E3A8A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      goldGradient: LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0F294A),
        onPrimary: Colors.white,
        secondary: Color(0xFFD97706),
        onSecondary: Colors.white,
        tertiary: Color(0xFF1E3A8A),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0F172A),
        outline: Color(0xFFE2E8F0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0xFF162D59).withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF162D59));
          }
          return const IconThemeData(color: Color(0xFF64748B));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF162D59),
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF162D59),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF162D59),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF162D59), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF60A5FA),
        onPrimary: Color(0xFF0B1120),
        secondary: Color(0xFFFBBF24),
        onSecondary: Color(0xFF0B1120),
        tertiary: Color(0xFFFB923C),
        surface: Color(0xFF1E293B),
        onSurface: Color(0xFFF8FAFC),
        outline: Color(0xFF334155),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF60A5FA).withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF60A5FA));
          }
          return const IconThemeData(color: Color(0xFF94A3B8));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF60A5FA),
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF60A5FA),
          foregroundColor: const Color(0xFF0B1120),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF60A5FA),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
