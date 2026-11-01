import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

class KCard extends StatelessWidget {
  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.selected = false,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);
    final effectiveBorder = borderColor ?? (selected ? p.primary : p.outline);
    final effectiveBg = backgroundColor ??
        (selected ? p.primary.withValues(alpha: 0.10) : p.surface);

    final cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveBorder,
          width: selected ? 2.2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveBorder,
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return cardBody;

    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: cardBody,
          ),
        ),
      ),
    );
  }
}
