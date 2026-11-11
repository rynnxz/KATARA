import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

enum PathNodeStatus { locked, active, completed, boss }

class PathNode extends StatelessWidget {
  const PathNode({
    super.key,
    required this.title,
    required this.status,
    this.subtitle,
    this.stars = 0,
    this.onTap,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final PathNodeStatus status;
  final int stars;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);
    final isLocked = status == PathNodeStatus.locked;
    final isBoss = status == PathNodeStatus.boss;

    final (
      Color faceColor,
      Color lipColor,
      Color fgColor,
      IconData defaultIcon,
    ) = switch (status) {
      PathNodeStatus.locked => (
        p.surfaceAlt,
        p.outline,
        p.inkMuted,
        Icons.lock_rounded,
      ),
      PathNodeStatus.active => (
        p.primary,
        p.primaryDark,
        p.onPrimary,
        Icons.play_arrow_rounded,
      ),
      PathNodeStatus.completed => (
        p.secondary,
        const Color(0xFFC28E00),
        p.onSecondary,
        Icons.check_rounded,
      ),
      PathNodeStatus.boss => (
        p.accent,
        const Color(0xFF751D1D),
        Colors.white,
        Icons.workspace_premium_rounded,
      ),
    };

    return Semantics(
      button: !isLocked && onTap != null,
      enabled: !isLocked,
      label: '$title (${isLocked ? "Terkunci" : "Bintang $stars dari 3"})',
      child: MouseRegion(
        cursor: isLocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isLocked ? null : onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == PathNodeStatus.completed || stars > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final earned = index < stars;
                      return Icon(
                        earned ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 18,
                        color: earned ? p.secondary : p.outline,
                      );
                    }),
                  ),
                ),
              Container(
                width: isBoss ? 80 : 70,
                height: isBoss ? 80 : 70,
                padding: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: lipColor,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: faceColor,
                    shape: BoxShape.circle,
                    border: status == PathNodeStatus.active
                        ? Border.all(color: p.secondary, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon ?? defaultIcon,
                      size: isBoss ? 34 : 30,
                      color: fgColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isLocked ? p.inkMuted : p.ink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: p.inkMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
