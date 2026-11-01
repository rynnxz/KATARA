import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

class KHeaderStats extends StatelessWidget {
  const KHeaderStats({
    super.key,
    required this.streak,
    required this.coins,
    required this.hearts,
    required this.xp,
    this.heartsEnabled = true,
    this.onRegionTap,
    this.regionLabel,
  });

  final int streak;
  final int coins;
  final int hearts;
  final int xp;
  final bool heartsEnabled;
  final VoidCallback? onRegionTap;
  final String? regionLabel;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (regionLabel != null)
          Semantics(
            button: onRegionTap != null,
            label: 'Daerah aktif: $regionLabel',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onRegionTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_rounded, size: 16, color: p.primary),
                    const SizedBox(width: 4),
                    Text(
                      regionLabel!,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: p.ink,
                      ),
                    ),
                    if (onRegionTap != null) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.expand_more_rounded, size: 16, color: p.inkMuted),
                    ],
                  ],
                ),
              ),
            ),
          ),
        _StatPill(
          icon: Icons.local_fire_department_rounded,
          iconColor: p.streak,
          value: '$streak',
          semanticLabel: 'Streak $streak hari',
        ),
        _StatPill(
          icon: Icons.monetization_on_rounded,
          iconColor: p.coin,
          value: '$coins',
          semanticLabel: '$coins koin',
        ),
        _StatPill(
          icon: heartsEnabled ? Icons.favorite_rounded : Icons.spa_rounded,
          iconColor: heartsEnabled ? p.heart : p.primary,
          value: heartsEnabled ? '$hearts' : 'Bebas',
          semanticLabel: heartsEnabled ? '$hearts nyawa' : 'Mode tanpa pengurangan nyawa',
        ),
        _StatPill(
          icon: Icons.bolt_rounded,
          iconColor: p.secondary,
          value: '$xp XP',
          semanticLabel: '$xp total XP',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);
    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
