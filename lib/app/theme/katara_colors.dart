import 'dart:math' as math;
import 'package:flutter/material.dart';

@immutable
class KataraPalette extends ThemeExtension<KataraPalette> {
  const KataraPalette({
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.ink,
    required this.inkMuted,
    required this.success,
    required this.error,
    required this.streak,
    required this.heart,
    required this.coin,
  });

  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color accent;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color outline;
  final Color ink;
  final Color inkMuted;
  final Color success;
  final Color error;
  final Color streak;
  final Color heart;
  final Color coin;

  // Token warna resmi Bagian 10.2 (Hijau Rebung, Kuning Diraja, Merah Songket).
  static const KataraPalette light = KataraPalette(
    primary: Color(0xFF1E7F5C),
    primaryDark: Color(0xFF14573F),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFF5B700),
    onSecondary: Color(0xFF2B2118),
    accent: Color(0xFFA62B2B),
    bg: Color(0xFFFFF9EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6EEDC),
    outline: Color(0xFFE5D9BF),
    ink: Color(0xFF2B2118),
    inkMuted: Color(0xFF6B5E4B),
    success: Color(0xFF2E9E5B),
    error: Color(0xFFD2453B),
    streak: Color(0xFFF28C28),
    heart: Color(0xFFE5484D),
    coin: Color(0xFFE0A800),
  );

  static const KataraPalette dark = KataraPalette(
    primary: Color(0xFF3FBF8A),
    primaryDark: Color(0xFF2C9A6C),
    onPrimary: Color(0xFF0F1F18),
    secondary: Color(0xFFFFC933),
    onSecondary: Color(0xFF2B2118),
    accent: Color(0xFFE0605F),
    bg: Color(0xFF15110C),
    surface: Color(0xFF211B14),
    surfaceAlt: Color(0xFF2C241A),
    outline: Color(0xFF3B3224),
    ink: Color(0xFFF6EDDC),
    inkMuted: Color(0xFFB9AB92),
    success: Color(0xFF4CD08A),
    error: Color(0xFFFF6B6B),
    streak: Color(0xFFFFA94D),
    heart: Color(0xFFFF7A7E),
    coin: Color(0xFFFFD54F),
  );

  static KataraPalette of(BuildContext context) {
    final courseAccent = CourseTheme.maybeAccentOf(context);
    final base = Theme.of(context).extension<KataraPalette>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
    if (courseAccent != null) {
      return base.copyWith(secondary: courseAccent);
    }
    return base;
  }

  @override
  KataraPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? accent,
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? outline,
    Color? ink,
    Color? inkMuted,
    Color? success,
    Color? error,
    Color? streak,
    Color? heart,
    Color? coin,
  }) {
    return KataraPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      accent: accent ?? this.accent,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      outline: outline ?? this.outline,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      success: success ?? this.success,
      error: error ?? this.error,
      streak: streak ?? this.streak,
      heart: heart ?? this.heart,
      coin: coin ?? this.coin,
    );
  }

  @override
  KataraPalette lerp(ThemeExtension<KataraPalette>? other, double t) {
    if (other is! KataraPalette) return this;
    return KataraPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      heart: Color.lerp(heart, other.heart, t)!,
      coin: Color.lerp(coin, other.coin, t)!,
    );
  }
}

class KataraColors {
  const KataraColors._();

  static double relativeLuminance(Color c) {
    double linearize(double channel) {
      if (channel <= 0.03928) {
        return channel / 12.92;
      }
      return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(c.r);
    final g = linearize(c.g);
    final b = linearize(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color parseHex(String hex, {Color fallback = const Color(0xFFF5B700)}) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    } else if (cleaned.length == 8) {
      final value = int.tryParse(cleaned, radix: 16);
      if (value != null) return Color(value);
    }
    return fallback;
  }
}

/// Menimpa token warna `secondary` sesuai `accent_hex` daerah/course aktif (Bagian 10.2).
class CourseTheme extends InheritedWidget {
  CourseTheme({
    super.key,
    Color? accentColor,
    String? accentHex,
    this.isComingSoon = false,
    required super.child,
  }) : accentColor = isComingSoon
            ? const Color(0xFF9AA0A6)
            : (accentColor ??
                (accentHex != null
                    ? KataraColors.parseHex(accentHex)
                    : const Color(0xFFF5B700)));

  final Color accentColor;
  final bool isComingSoon;

  static Color? maybeAccentOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CourseTheme>()
        ?.accentColor;
  }

  @override
  bool updateShouldNotify(CourseTheme oldWidget) =>
      oldWidget.accentColor != accentColor ||
      oldWidget.isComingSoon != isComingSoon;
}

extension KataraPaletteContext on BuildContext {
  KataraPalette get kataraPalette => KataraPalette.of(this);
}
