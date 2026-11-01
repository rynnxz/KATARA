import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

enum MascotState {
  idle,
  happy,
  sad,
  cheer,
}

/// Maskot resmi KATARA: **Si Rebung** (tunas rebung memakai tanjak Melayu).
/// Digambar dengan `CustomPainter` agar tajam di semua ukuran tanpa aset eksternal (Bagian 10.4).
class MascotView extends StatelessWidget {
  const MascotView({
    super.key,
    this.state = MascotState.idle,
    this.size = 96,
    this.outfitId,
    this.showLabel = false,
  });

  final MascotState state;
  final double size;
  final String? outfitId;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final palette = KataraPalette.of(context);
    final labelText = switch (state) {
      MascotState.idle => 'Si Rebung siap menemani belajar',
      MascotState.happy => 'Si Rebung senang',
      MascotState.sad => 'Si Rebung menyemangati kembali',
      MascotState.cheer => 'Si Rebung bersorak bangga',
    };

    return Semantics(
      label: labelText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _SiRebungPainter(
                state: state,
                palette: palette,
                outfitId: outfitId,
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            Text(
              'Si Rebung',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _SiRebungPainter extends CustomPainter {
  const _SiRebungPainter({
    required this.state,
    required this.palette,
    this.outfitId,
  });

  final MascotState state;
  final KataraPalette palette;
  final String? outfitId;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Lingkaran latar lembut.
    canvas.drawCircle(
      Offset(cx, h * 0.54),
      w * 0.42,
      Paint()..color = palette.surfaceAlt,
    );

    // Badan tunas rebung (hijau rebung).
    final bodyPath = Path()
      ..moveTo(cx, h * 0.16)
      ..quadraticBezierTo(w * 0.80, h * 0.45, w * 0.74, h * 0.82)
      ..quadraticBezierTo(cx, h * 0.90, w * 0.26, h * 0.82)
      ..quadraticBezierTo(w * 0.20, h * 0.45, cx, h * 0.16)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = palette.primary);

    // Kelopak rebung bawah (aksen lebih gelap).
    final leafLeft = Path()
      ..moveTo(w * 0.25, h * 0.62)
      ..quadraticBezierTo(w * 0.42, h * 0.72, cx, h * 0.86)
      ..lineTo(w * 0.26, h * 0.82)
      ..close();
    final leafRight = Path()
      ..moveTo(w * 0.75, h * 0.62)
      ..quadraticBezierTo(w * 0.58, h * 0.72, cx, h * 0.86)
      ..lineTo(w * 0.74, h * 0.82)
      ..close();
    final darkLeafPaint = Paint()..color = palette.primaryDark;
    canvas.drawPath(leafLeft, darkLeafPaint);
    canvas.drawPath(leafRight, darkLeafPaint);

    // Wajah krem hangat.
    final faceRect = Rect.fromCenter(
      center: Offset(cx, h * 0.55),
      width: w * 0.38,
      height: h * 0.30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, Radius.circular(w * 0.16)),
      Paint()..color = const Color(0xFFFFF3D6),
    );

    // Tanjak Melayu di atas kepala (Kuning Diraja + pita Merah Songket).
    final tanjakPath = Path()
      ..moveTo(w * 0.24, h * 0.36)
      ..lineTo(w * 0.54, h * 0.13)
      ..lineTo(w * 0.77, h * 0.34)
      ..lineTo(w * 0.74, h * 0.41)
      ..lineTo(w * 0.26, h * 0.41)
      ..close();
    canvas.drawPath(tanjakPath, Paint()..color = palette.secondary);

    final songketBand = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.36, w * 0.48, h * 0.055),
      const Radius.circular(4),
    );
    canvas.drawRRect(songketBand, Paint()..color = palette.accent);

    // Mata & ekspresi sesuai state.
    final eyePaint = Paint()
      ..color = const Color(0xFF2B2118)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.028)
      ..strokeCap = StrokeCap.round;
    final eyeFill = Paint()..color = const Color(0xFF2B2118);

    final leftEyeX = cx - w * 0.08;
    final rightEyeX = cx + w * 0.08;
    final eyeY = h * 0.52;

    if (state == MascotState.happy || state == MascotState.cheer) {
      // Mata melengkung gembira.
      canvas.drawArc(
        Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: w * 0.07, height: w * 0.06),
        math.pi,
        math.pi,
        false,
        eyePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: w * 0.07, height: w * 0.06),
        math.pi,
        math.pi,
        false,
        eyePaint,
      );
    } else {
      canvas.drawCircle(Offset(leftEyeX, eyeY), w * 0.026, eyeFill);
      canvas.drawCircle(Offset(rightEyeX, eyeY), w * 0.026, eyeFill);
    }

    // Mulut.
    final mouthY = h * 0.60;
    if (state == MascotState.sad) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, mouthY + h * 0.03), width: w * 0.10, height: w * 0.06),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        eyePaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, mouthY - h * 0.01), width: w * 0.12, height: w * 0.08),
        0.15,
        math.pi - 0.3,
        false,
        eyePaint,
      );
    }

    // Bintang kecil saat state cheer.
    if (state == MascotState.cheer) {
      final starPaint = Paint()..color = palette.secondary;
      canvas.drawCircle(Offset(w * 0.14, h * 0.26), w * 0.04, starPaint);
      canvas.drawCircle(Offset(w * 0.86, h * 0.24), w * 0.045, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiRebungPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.palette != palette ||
      oldDelegate.outfitId != outfitId;
}
