import 'dart:math' as math;
import 'package:flutter/material.dart';

@immutable
class KataraPalette extends ThemeExtension<KataraPalette> {
  const KataraPalette({
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.accent,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.ink,
    required this.inkMuted,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.streak,
    required this.heart,
    required this.coin,
  });

  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color accent;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color outline;
  final Color ink;
  final Color inkMuted;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color streak;
  final Color heart;
  final Color coin;

  /// Token warna resmi Bagian 10.2 dengan peningkatan kontras WCAG 2.1 AA+ / AAA:
  /// - Seluruh kontainer (`primaryContainer`, `secondaryContainer`, `successContainer`, `errorContainer`)
  ///   bersifat 100% solid (`alpha: 1.0`) agar bayangan 3D (`BoxShadow`) tidak pernah tembus ke latar kartu.
  /// - Teks utama (`ink`) dan teks sekunder (`inkMuted`) memenuhi rasio kontras >= 7:1 (AAA).
  /// - Garis tepi (`outline`) memenuhi rasio kontras non-teks >= 3:1 terhadap `bg`, `surface`, dan `surfaceAlt`.
  static const KataraPalette light = KataraPalette(
    primary: Color(0xFF186B4C),
    primaryDark: Color(0xFF114D36),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE2F5EC),
    onPrimaryContainer: Color(0xFF0D3B29),
    secondary: Color(0xFFF5B700),
    onSecondary: Color(0xFF221910),
    secondaryContainer: Color(0xFFFFF0BD),
    onSecondaryContainer: Color(0xFF221910),
    accent: Color(0xFFA62B2B),
    bg: Color(0xFFFFF9EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6EEDC),
    outline: Color(0xFF786954),
    ink: Color(0xFF221910),
    inkMuted: Color(0xFF4A3E2D),
    success: Color(0xFF1B6B3A),
    successContainer: Color(0xFFDCF5E4),
    onSuccessContainer: Color(0xFF0F3D22),
    error: Color(0xFFB8251E),
    errorContainer: Color(0xFFFCE4E4),
    onErrorContainer: Color(0xFF5C1111),
    streak: Color(0xFFB55309),
    heart: Color(0xFFB8252B),
    coin: Color(0xFF9E6B00),
  );

  static const KataraPalette dark = KataraPalette(
    primary: Color(0xFF3FBF8A),
    primaryDark: Color(0xFF2C9A6C),
    onPrimary: Color(0xFF0F1F18),
    primaryContainer: Color(0xFF132E23),
    onPrimaryContainer: Color(0xFFCFFAE6),
    secondary: Color(0xFFFFC933),
    onSecondary: Color(0xFF221910),
    secondaryContainer: Color(0xFF3D2E05),
    onSecondaryContainer: Color(0xFFFFE799),
    accent: Color(0xFFE0605F),
    bg: Color(0xFF15110C),
    surface: Color(0xFF211B14),
    surfaceAlt: Color(0xFF2C241A),
    outline: Color(0xFF8C7D68),
    ink: Color(0xFFF8F1E3),
    inkMuted: Color(0xFFD8CCB8),
    success: Color(0xFF4CD08A),
    successContainer: Color(0xFF123321),
    onSuccessContainer: Color(0xFFC6F7DC),
    error: Color(0xFFFF6B6B),
    errorContainer: Color(0xFF3D1414),
    onErrorContainer: Color(0xFFFFCDD2),
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
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? accent,
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? outline,
    Color? ink,
    Color? inkMuted,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? error,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? streak,
    Color? heart,
    Color? coin,
  }) {
    return KataraPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      accent: accent ?? this.accent,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      outline: outline ?? this.outline,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
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
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer:
          Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
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
    required this.onAccentColor,
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
  final Color onAccentColor;
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
    onAccentColor: Color(0xFF221910),
    secondaryColor: Color(0xFF186B4C),
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
    accentColor: Color(0xFF186B4C),
    onAccentColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFFB55309),
    badgeBgLight: Color(0xFFDDF5EB),
    badgeFgLight: Color(0xFF0D3B29),
    badgeBgDark: Color(0xFF123D2D),
    badgeFgDark: Color(0xFFA7F3D0),
    motifName: 'Tampuk Manggis Songket Langkat',
    culturalTagline: 'Hijau Zamrud Pesisir & Emas Tampuk Manggis Tanjung Pura',
  );

  static const DialectVisualIdentity palembang = DialectVisualIdentity(
    courseId: 'ms-palembang',
    regionName: 'Sumatera Selatan • Palembang & Tepian Musi',
    accentColor: Color(0xFF8B1E24),
    onAccentColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFFB55309),
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

  static DialectVisualIdentity identityOf(
    BuildContext context, [
    String? fallbackCourseId,
  ]) {
    final inherited = context.dependOnInheritedWidgetOfExactType<CourseTheme>();
    return DialectVisualIdentity.forCourse(
      inherited?.courseId ?? fallbackCourseId,
    );
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
