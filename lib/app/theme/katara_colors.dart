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

  // Token warna resmi Bagian 10.2 dengan peningkatan kontras WCAG AA+ (AAA pada ink & inkMuted).
  static const KataraPalette light = KataraPalette(
    primary: Color(0xFF1E7F5C),
    primaryDark: Color(0xFF14573F),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFF5B700),
    onSecondary: Color(0xFF221910),
    accent: Color(0xFFA62B2B),
    bg: Color(0xFFFFF9EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6EEDC),
    outline: Color(0xFFCBBBA0),
    ink: Color(0xFF221910),
    inkMuted: Color(0xFF4A3E2D),
    success: Color(0xFF217A44),
    error: Color(0xFFC93329),
    streak: Color(0xFFD97214),
    heart: Color(0xFFD9383E),
    coin: Color(0xFFC99400),
  );

  static const KataraPalette dark = KataraPalette(
    primary: Color(0xFF3FBF8A),
    primaryDark: Color(0xFF2C9A6C),
    onPrimary: Color(0xFF0F1F18),
    secondary: Color(0xFFFFC933),
    onSecondary: Color(0xFF221910),
    accent: Color(0xFFE0605F),
    bg: Color(0xFF15110C),
    surface: Color(0xFF211B14),
    surfaceAlt: Color(0xFF2C241A),
    outline: Color(0xFF43382B),
    ink: Color(0xFFF8F1E3),
    inkMuted: Color(0xFFD8CCB8),
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

/// Identitas visual budaya per dialek Melayu (Deli, Langkat, Palembang).
@immutable
class DialectVisualIdentity {
  const DialectVisualIdentity({
    required this.courseId,
    required this.regionName,
    required this.accentColor,
    required this.secondaryColor,
    required this.badgeBgLight,
    required this.badgeFgLight,
    required this.badgeBgDark,
    required this.badgeFgDark,
    required this.motifName,
    required this.culturalTagline,
  });

  final String courseId;
  final String regionName;
  final Color accentColor;
  final Color secondaryColor;
  final Color badgeBgLight;
  final Color badgeFgLight;
  final Color badgeBgDark;
  final Color badgeFgDark;
  final String motifName;
  final String culturalTagline;

  static const DialectVisualIdentity deli = DialectVisualIdentity(
    courseId: 'ms-deli',
    regionName: 'Sumatera Utara • Medan & Deli Serdang',
    accentColor: Color(0xFFF5B700),
    secondaryColor: Color(0xFF1E7F5C),
    badgeBgLight: Color(0xFFFFF0BD),
    badgeFgLight: Color(0xFF221910),
    badgeBgDark: Color(0xFF473500),
    badgeFgDark: Color(0xFFFFE58F),
    motifName: 'Pucuk Rebung Kesultanan Deli',
    culturalTagline: 'Kuning Emas Diraja & Hijau Pucuk Rebung Maimun',
  );

  static const DialectVisualIdentity langkat = DialectVisualIdentity(
    courseId: 'ms-langkat',
    regionName: 'Sumatera Utara • Tanjung Pura & Pesisir Langkat',
    accentColor: Color(0xFF1E7F5C),
    secondaryColor: Color(0xFFD97706),
    badgeBgLight: Color(0xFFDDF5EB),
    badgeFgLight: Color(0xFF103F2D),
    badgeBgDark: Color(0xFF123D2D),
    badgeFgDark: Color(0xFFA7F3D0),
    motifName: 'Tampuk Manggis Songket Langkat',
    culturalTagline: 'Hijau Zamrud Pesisir & Emas Tampuk Manggis Tanjung Pura',
  );

  static const DialectVisualIdentity palembang = DialectVisualIdentity(
    courseId: 'ms-palembang',
    regionName: 'Sumatera Selatan • Palembang & Tepian Musi',
    accentColor: Color(0xFF8B1E24),
    secondaryColor: Color(0xFFD97706),
    badgeBgLight: Color(0xFFFCE4E6),
    badgeFgLight: Color(0xFF4C0D11),
    badgeBgDark: Color(0xFF4C1115),
    badgeFgDark: Color(0xFFFECDD3),
    motifName: 'Songket Lepus Sriwijaya Palembang',
    culturalTagline: 'Merah Lakuer Sriwijaya & Benang Emas Songket Lepus',
  );

  static DialectVisualIdentity forCourse(String? courseId) {
    return switch (courseId) {
      'ms-langkat' || 'melayu_langkat' => langkat,
      'ms-palembang' || 'melayu_palembang' => palembang,
      _ => deli,
    };
  }
}

/// Menimpa token warna `secondary` sesuai `accent_hex` daerah/course aktif (Bagian 10.2).
class CourseTheme extends InheritedWidget {
  CourseTheme({
    super.key,
    Color? accentColor,
    String? accentHex,
    this.courseId,
    this.isComingSoon = false,
    required super.child,
  }) : accentColor = isComingSoon
            ? const Color(0xFF4A3E2D)
            : (accentColor ??
                (accentHex != null
                    ? KataraColors.parseHex(accentHex)
                    : DialectVisualIdentity.forCourse(courseId).accentColor));

  final Color accentColor;
  final String? courseId;
  final bool isComingSoon;

  static Color? maybeAccentOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CourseTheme>()
        ?.accentColor;
  }

  static DialectVisualIdentity identityOf(BuildContext context, [String? fallbackCourseId]) {
    final inherited = context.dependOnInheritedWidgetOfExactType<CourseTheme>();
    return DialectVisualIdentity.forCourse(inherited?.courseId ?? fallbackCourseId);
  }

  @override
  bool updateShouldNotify(CourseTheme oldWidget) =>
      oldWidget.accentColor != accentColor ||
      oldWidget.courseId != courseId ||
      oldWidget.isComingSoon != isComingSoon;
}

extension KataraPaletteContext on BuildContext {
  KataraPalette get kataraPalette => KataraPalette.of(this);
}
