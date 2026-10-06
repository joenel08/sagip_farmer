// ============================================================
// lib/theme/app_theme.dart
// Design system for SAGIPfarmer — modern green palette.
// ============================================================
import 'package:flutter/material.dart';

class AppColors {
  // ─── Green scale ───
  static const green50  = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green200 = Color(0xFFBBF7D0);
  static const green300 = Color(0xFF86EFAC);
  static const green400 = Color(0xFF4ADE80);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const green700 = Color(0xFF15803D);
  static const green800 = Color(0xFF166534);
  static const green900 = Color(0xFF14532D);
  static const green950 = Color(0xFF052E16);
  static const lime    = Color(0xFFA3E635);

  // ─── Neutrals ───
  static const ink    = Color(0xFF0B1A12);
  static const muted  = Color(0xFF5B6F63);
  static const line   = Color(0xFFE2EFE6);
  static const white  = Color(0xFFFFFFFF);
  static const bg     = Color(0xFFF7FBF8);

  // ─── Status ───
  static const danger  = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info    = Color(0xFF2563EB);
  static const soil    = Color(0xFF8D6E63);
}

class AppGradients {
  /// Main brand gradient — sidebar, app bars, hero cards
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.green600, AppColors.green800],
  );

  /// Deeper variant for splash/login
  static const deep = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.green700, AppColors.green950],
  );

  /// Soft green wash for backgrounds
  static const soft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.green50, AppColors.bg],
  );

  /// Lime accent gradient — buttons, chips
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.green400, AppColors.lime],
  );

  /// Water card gradient
  static const water = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
  );

  /// Soil card gradient
  static const soil = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
  );
}

class AppShadows {
  static const sm = [
    BoxShadow(
      color: Color(0x0F064E3B),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const base = [
    BoxShadow(
      color: Color(0x2E064E3B),
      blurRadius: 30,
      offset: Offset(0, 12),
      spreadRadius: -10,
    ),
  ];

  static const lg = [
    BoxShadow(
      color: Color(0x47064E3B),
      blurRadius: 60,
      offset: Offset(0, 30),
      spreadRadius: -20,
    ),
  ];
}

class AppRadius {
  static const sm  = 12.0;
  static const md  = 18.0;
  static const lg  = 28.0;
  static const xl  = 32.0;
  static const pill = 999.0;
}

class AppText {
  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.ink,
    height: 1.5,
  );

  static const muted = TextStyle(
    fontSize: 13,
    color: AppColors.muted,
    height: 1.5,
  );

  static const tiny = TextStyle(
    fontSize: 11,
    color: AppColors.muted,
    letterSpacing: 0.5,
  );
}

/// The full app theme.
class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.green700,
        onPrimary: Colors.white,
        secondary: AppColors.lime,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        prefixIconColor: AppColors.green700,
        suffixIconColor: AppColors.green700,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.green600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green700,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green700,
          side: const BorderSide(color: AppColors.green700, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green700,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}