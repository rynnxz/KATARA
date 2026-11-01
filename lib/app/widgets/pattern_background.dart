import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

/// Motif geometri Pucuk Rebung Melayu digambar dengan `CustomPainter` (tanpa aset eksternal).
/// Dipakai sebagai identitas budaya pada splash, header peta, dan layar hasil (Bagian 10.4, R-07).
class PatternBackground extends StatelessWidget {
  const PatternBackground({
    super.key,
    required this.child,
    this.opacity = 0.06,
    this.patternColor,
  });

  final Widget child;
  final double opacity;
  final Color? patternColor;

  @override
  Widget build(BuildContext context) {
    final palette = KataraPalette.of(context);
    final color = (patternColor ?? palette.primary).withValues(alpha: opacity);

    return CustomPaint(
      painter: _PucukRebungPainter(color: color),
      child: child,
    );
  }
}

class _PucukRebungPainter extends CustomPainter {
  const _PucukRebungPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const tileW = 48.0;
    const tileH = 56.0;

    for (double y = 0; y < size.height + tileH; y += tileH) {
      final rowOffset = ((y ~/ tileH).isOdd) ? tileW / 2 : 0.0;
      for (double x = -tileW; x < size.width + tileW; x += tileW) {
        final cx = x + rowOffset + tileW / 2;
        final topY = y + 6;
        final botY = y + tileH - 6;

        // Segitiga luar Pucuk Rebung (tunas bambu menjulang ke atas).
        final outer = Path()
          ..moveTo(cx, topY)
          ..lineTo(cx + tileW * 0.36, botY)
          ..lineTo(cx - tileW * 0.36, botY)
          ..close();
        canvas.drawPath(outer, paint);

        // Segitiga dalam berjenjang.
        final inner = Path()
          ..moveTo(cx, topY + 12)
          ..lineTo(cx + tileW * 0.18, botY - 6)
          ..lineTo(cx - tileW * 0.18, botY - 6)
          ..close();
        canvas.drawPath(inner, paint);

        // Titik puncak pucuk rebung.
        canvas.drawCircle(
          Offset(cx, topY + 4),
          1.6,
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PucukRebungPainter oldDelegate) =>
      oldDelegate.color != color;
}
