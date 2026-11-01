import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

class KProgressBar extends StatelessWidget {
  const KProgressBar({
    super.key,
    required this.value,
    this.height = 14,
    this.color,
    this.backgroundColor,
    this.semanticLabel,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      label: semanticLabel ?? 'Progres',
      value: '${(clamped * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? p.surfaceAlt,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: p.outline, width: 1.2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * clamped,
                height: height,
                decoration: BoxDecoration(
                  color: color ?? p.primary,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
