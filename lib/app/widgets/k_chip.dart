import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.backgroundColor,
    Color? foregroundColor,
    Color? textColor,
  }) : foregroundColor = foregroundColor ?? textColor;

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);
    final rawBg = backgroundColor ?? (selected ? p.primary : p.surfaceAlt);
    final bg = rawBg.a < 1.0 ? Color.alphaBlend(rawBg, p.surface) : rawBg;
    final rawFg = foregroundColor ?? (selected ? p.onPrimary : p.ink);
    final fg = rawFg.a < 1.0 ? Color.alphaBlend(rawFg, bg) : rawFg;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? p.primaryDark : p.outline,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: chip,
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge status validasi konten sesuai Bagian 14 & keputusan transparansi ilmiah:
/// - `expert_verified`     -> "Terverifikasi Ahli"
/// - `speaker_checked`     -> "Dicek Penutur" (khusus yang telah dicek langsung bersama penutur jati)
/// - `dictionary_verified` -> "Sumber Kamus" (terverifikasi dari kamus/literatur resmi Balai Bahasa)
/// - `draft`               -> "Draf"
class ValidationStatusBadge extends StatelessWidget {
  const ValidationStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);
    final (String text, IconData icon, Color bg, Color fg) = switch (status) {
      'expert_verified' => (
          'Terverifikasi Ahli',
          Icons.verified_rounded,
          p.successContainer,
          p.onSuccessContainer,
        ),
      'speaker_checked' => (
          'Dicek Penutur',
          Icons.check_circle_outline_rounded,
          p.primaryContainer,
          p.onPrimaryContainer,
        ),
      'dictionary_verified' => (
          'Sumber Kamus',
          Icons.menu_book_rounded,
          p.primaryContainer,
          p.onPrimaryContainer,
        ),
      _ => (
          'Draf',
          Icons.edit_note_rounded,
          p.secondaryContainer,
          p.onSecondaryContainer,
        ),
    };

    return KChip(
      label: text,
      icon: icon,
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }
}

/// Badge identitas dialek daerah dengan kontras tinggi (WCAG AA+ >= 4.5:1).
class DialectIdentityBadge extends StatelessWidget {
  const DialectIdentityBadge({
    super.key,
    required this.courseId,
    this.labelOverride,
  });

  final String courseId;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final identity = DialectVisualIdentity.forCourse(courseId);
    final bg = isDark ? identity.badgeBgDark : identity.badgeBgLight;
    final fg = isDark ? identity.badgeFgDark : identity.badgeFgLight;
    final label = labelOverride ??
        switch (courseId) {
          'ms-langkat' || 'melayu_langkat' => 'Melayu Langkat',
          'ms-palembang' || 'melayu_palembang' => 'Melayu Palembang',
          _ => 'Melayu Deli',
        };

    return KChip(
      label: label,
      icon: Icons.public_rounded,
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }
}
