import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — matte, flat, soft geometry
class AppRadii {
  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

class AppShadows {
  /// Soft matte shadow (light mode)
  static List<BoxShadow> soft(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF1A1D24).withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: const Color(0xFF1A1D24).withValues(alpha: 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> hairline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];
  }
}

class AppTheme {
  static const Color _seedLight = Color(0xFF5B6CFF);
  static const Color _seedDark = Color(0xFF8B9BFF);

  // Matte surface palette
  static const Color _bgLight = Color(0xFFF4F5F8);
  static const Color _bgDark = Color(0xFF0C0D10);
  static const Color _cardLight = Color(0xFFFBFBFC);
  static const Color _cardDark = Color(0xFF16181D);
  static const Color _mutedLight = Color(0xFFEEF0F4);
  static const Color _mutedDark = Color(0xFF1E2128);

  static ThemeData light({bool useDynamicColor = true}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedLight,
      brightness: Brightness.light,
      surface: _cardLight,
    );
    return _buildTheme(colorScheme, Brightness.light);
  }

  static ThemeData dark({bool useDynamicColor = true}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedDark,
      brightness: Brightness.dark,
      surface: _cardDark,
    );
    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Clean geometric sans — Inter for UI clarity
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -1.2, height: 1.15),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.15),
      displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.2),
      headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.2),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.25),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.35),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.35),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.45),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.4),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.3),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.3),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, letterSpacing: 0.2, height: 1.3),
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final cardColor = isDark ? _cardDark : _cardLight;
    final bgColor = isDark ? _bgDark : _bgLight;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgColor.withValues(alpha: 0.92),
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
          side: BorderSide(color: borderColor),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _mutedDark : _mutedLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.7), width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurface.withValues(alpha: 0.15),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: isDark ? _mutedDark : const Color(0xFF1A1D24),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.1,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.45),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.45),
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
        side: BorderSide(color: borderColor),
        backgroundColor: isDark ? _mutedDark : _mutedLight,
        labelStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return isDark ? Colors.white70 : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return colorScheme.primary;
          return isDark ? _mutedDark : _mutedLight;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
