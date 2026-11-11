import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

/// Motif geometri Nusantara per dialek Melayu digambar dengan `CustomPainter` (tanpa aset eksternal):
/// - `ms-deli`: Pucuk Rebung Kesultanan Deli
/// - `ms-langkat`: Tampuk Manggis Songket Langkat
/// - `ms-palembang`: Songket Lepus Bunga Cina Sriwijaya
class PatternBackground extends StatelessWidget {
  const PatternBackground({
    super.key,
    required this.child,
    this.opacity = 0.06,
    this.patternColor,
    this.courseId,
  });

  final Widget child;
  final double opacity;
  final Color? patternColor;
  final String? courseId;

  @override
  Widget build(BuildContext context) {
    final palette = KataraPalette.of(context);
    final effectiveCourseId =
        courseId ??
        context.dependOnInheritedWidgetOfExactType<CourseTheme>()?.courseId;
    final identity = DialectVisualIdentity.forCourse(effectiveCourseId);
    final baseColor =
        patternColor ??
        (effectiveCourseId != null ? identity.accentColor : palette.primary);
    final color = baseColor.withValues(alpha: opacity);

    return CustomPaint(
      painter: _DialectOrnamentPainter(
        color: color,
        courseId: identity.courseId,
      ),
      child: child,
    );
  }
}

class _DialectOrnamentPainter extends CustomPainter {
  const _DialectOrnamentPainter({required this.color, required this.courseId});

  final Color color;
  final String courseId;

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
        final cy = y + tileH / 2;
        final topY = y + 6;
        final botY = y + tileH - 6;

        if (courseId == 'ms-langkat') {
          // Tampuk Manggis: oktagon berlapis dengan kelopak simetris.
          final rOuter = tileW * 0.34;
          final rInner = tileW * 0.16;
          final diamond = Path()
            ..moveTo(cx, cy - rOuter)
            ..lineTo(cx + rOuter, cy)
            ..lineTo(cx, cy + rOuter)
            ..lineTo(cx - rOuter, cy)
            ..close();
          canvas.drawPath(diamond, paint);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: rInner * 2,
              height: rInner * 2,
            ),
            paint,
          );
          canvas.drawCircle(Offset(cx, cy), 2.0, Paint()..color = color);
        } else if (courseId == 'ms-palembang') {
          // Songket Lepus / Bunga Cina: belah ketupat bersilang dengan bintang 4 sudut.
          final r = tileW * 0.36;
          final outer = Path()
            ..moveTo(cx, cy - r)
            ..lineTo(cx + r, cy)
            ..lineTo(cx, cy + r)
            ..lineTo(cx - r, cy)
            ..close();
          canvas.drawPath(outer, paint);
          canvas.drawLine(
            Offset(cx - r * 0.55, cy),
            Offset(cx + r * 0.55, cy),
            paint,
          );
          canvas.drawLine(
            Offset(cx, cy - r * 0.55),
            Offset(cx, cy + r * 0.55),
            paint,
          );
          canvas.drawCircle(Offset(cx, cy), 2.2, Paint()..color = color);
        } else {
          // Default (ms-deli): Segitiga luar Pucuk Rebung (tunas bambu menjulang ke atas).
          final outer = Path()
            ..moveTo(cx, topY)
            ..lineTo(cx + tileW * 0.36, botY)
            ..lineTo(cx - tileW * 0.36, botY)
            ..close();
          canvas.drawPath(outer, paint);

          final inner = Path()
            ..moveTo(cx, topY + 12)
            ..lineTo(cx + tileW * 0.18, botY - 6)
            ..lineTo(cx - tileW * 0.18, botY - 6)
            ..close();
          canvas.drawPath(inner, paint);

          canvas.drawCircle(Offset(cx, topY + 4), 1.6, Paint()..color = color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DialectOrnamentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.courseId != courseId;
}
