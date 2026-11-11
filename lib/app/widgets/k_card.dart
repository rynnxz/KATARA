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
    final rawBorder = borderColor ?? (selected ? p.primary : p.outline);
    final effectiveBorder = rawBorder.a < 1.0
        ? Color.alphaBlend(rawBorder, p.surface)
        : rawBorder;
    final rawBg =
        backgroundColor ?? (selected ? p.primaryContainer : p.surface);
    // Wajib 100% solid (alpha == 1.0) agar BoxShadow 3D di bawah kartu tidak pernah tembus ke permukaan kartu.
    final effectiveBg = rawBg.a < 1.0
        ? Color.alphaBlend(rawBg, p.surface)
        : rawBg;
    final defaultFg = selected ? p.onPrimaryContainer : p.ink;

    final cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: effectiveBorder, width: selected ? 2.2 : 1.5),
        boxShadow: [
          BoxShadow(
            color: effectiveBorder,
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: defaultFg),
          child: IconTheme.merge(
            data: IconThemeData(color: defaultFg),
            child: child,
          ),
        ),
      ),
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
