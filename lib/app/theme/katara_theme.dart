import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

class KataraTypography {
  const KataraTypography._();

  static const String uiFont = 'Nunito';
  static const String jawiFont = 'Noto Naskh Arabic';

  static TextStyle display(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: color,
      );

  static TextStyle title(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: color,
      );

  static TextStyle label(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle jawi({
    required Color color,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      TextStyle(
        fontFamily: jawiFont,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.6,
        color: color,
      );
}

class KataraTheme {
  const KataraTheme._();

  static ThemeData light() => _build(Brightness.light, KataraPalette.light);
  static ThemeData dark() => _build(Brightness.dark, KataraPalette.dark);

  static ThemeData _build(Brightness brightness, KataraPalette p) {
    final isDark = brightness == Brightness.dark;
    final inverseSurface = isDark ? const Color(0xFFFFF9EC) : const Color(0xFF221910);
    final onInverseSurface = isDark ? const Color(0xFF221910) : const Color(0xFFFFF9EC);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      secondaryContainer: p.secondaryContainer,
      onSecondaryContainer: p.onSecondaryContainer,
      error: p.error,
      onError: Colors.white,
      errorContainer: p.errorContainer,
      onErrorContainer: p.onErrorContainer,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      outline: p.outline,
      outlineVariant: p.outline,
      surfaceContainerHighest: p.surfaceAlt,
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: KataraTypography.uiFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bg,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: KataraTypography.title(p.ink),
        iconTheme: IconThemeData(color: p.ink),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.outline, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.outline,
        thickness: 1.2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KataraTypography.label(p.onPrimaryContainer).copyWith(fontWeight: FontWeight.w800);
          }
          return KataraTypography.label(p.inkMuted).copyWith(fontWeight: FontWeight.w700);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: p.onPrimaryContainer, size: 24);
          }
          return IconThemeData(color: p.inkMuted, size: 22);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inverseSurface,
        contentTextStyle: KataraTypography.body(onInverseSurface).copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        actionTextColor: p.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: KataraTypography.body(p.inkMuted).copyWith(fontSize: 15),
        labelStyle: KataraTypography.label(p.ink).copyWith(fontSize: 14),
        helperStyle: KataraTypography.label(p.inkMuted),
        prefixIconColor: p.inkMuted,
        suffixIconColor: p.inkMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 2.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        titleTextStyle: KataraTypography.title(p.ink),
        contentTextStyle: KataraTypography.body(p.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.outline, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.primary,
        labelStyle: KataraTypography.label(p.ink).copyWith(fontWeight: FontWeight.w700),
        secondaryLabelStyle: KataraTypography.label(p.onPrimary).copyWith(fontWeight: FontWeight.w700),
        side: BorderSide(color: p.outline, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: TextTheme(
        displayLarge: KataraTypography.display(p.ink),
        headlineMedium: KataraTypography.display(p.ink).copyWith(fontSize: 28),
        titleLarge: KataraTypography.title(p.ink),
        titleMedium: KataraTypography.title(p.ink).copyWith(fontSize: 18),
        titleSmall: KataraTypography.title(p.ink).copyWith(fontSize: 16),
        bodyLarge: KataraTypography.body(p.ink),
        bodyMedium: KataraTypography.body(p.ink).copyWith(fontSize: 15),
        bodySmall: KataraTypography.label(p.inkMuted),
        labelLarge: KataraTypography.label(p.ink).copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: KataraTypography.label(p.inkMuted),
        labelSmall: KataraTypography.label(p.inkMuted).copyWith(fontSize: 12),
      ),
    );
  }
}
