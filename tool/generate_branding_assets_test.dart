import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paints the official **Si Rebung** mascot onto [canvas] within [rect].
void paintSiRebung(
  Canvas canvas,
  Rect rect, {
  bool includeSoftCircle = false,
  Color softCircleColor = const Color(0xFFF6EEDC),
  Color bodyColor = const Color(0xFF186B4C),
  Color darkLeafColor = const Color(0xFF114D36),
  Color faceColor = const Color(0xFFFFF3D6),
  Color tanjakColor = const Color(0xFFF5B700),
  Color songketBandColor = const Color(0xFFA62B2B),
  Color eyeColor = const Color(0xFF2B2118),
  bool happyEyes = true,
}) {
  canvas.save();
  canvas.translate(rect.left, rect.top);
  final w = rect.width;
  final h = rect.height;
  final cx = w / 2;

  if (includeSoftCircle) {
    canvas.drawCircle(
      Offset(cx, h * 0.54),
      w * 0.44,
      Paint()
        ..color = softCircleColor
        ..isAntiAlias = true,
    );
  }

  final bodyPath = Path()
    ..moveTo(cx, h * 0.16)
    ..quadraticBezierTo(w * 0.80, h * 0.45, w * 0.74, h * 0.82)
    ..quadraticBezierTo(cx, h * 0.90, w * 0.26, h * 0.82)
    ..quadraticBezierTo(w * 0.20, h * 0.45, cx, h * 0.16)
    ..close();
  canvas.drawPath(
    bodyPath,
    Paint()
      ..color = bodyColor
      ..isAntiAlias = true,
  );

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
  final darkLeafPaint = Paint()
    ..color = darkLeafColor
    ..isAntiAlias = true;
  canvas.drawPath(leafLeft, darkLeafPaint);
  canvas.drawPath(leafRight, darkLeafPaint);

  final faceRect = Rect.fromCenter(
    center: Offset(cx, h * 0.55),
    width: w * 0.38,
    height: h * 0.30,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(faceRect, Radius.circular(w * 0.16)),
    Paint()
      ..color = faceColor
      ..isAntiAlias = true,
  );

  final tanjakPath = Path()
    ..moveTo(w * 0.24, h * 0.36)
    ..lineTo(w * 0.54, h * 0.13)
    ..lineTo(w * 0.77, h * 0.34)
    ..lineTo(w * 0.74, h * 0.41)
    ..lineTo(w * 0.26, h * 0.41)
    ..close();
  canvas.drawPath(
    tanjakPath,
    Paint()
      ..color = tanjakColor
      ..isAntiAlias = true,
  );

  final songketBand = RRect.fromRectAndRadius(
    Rect.fromLTWH(w * 0.26, h * 0.36, w * 0.48, h * 0.055),
    Radius.circular(math.max(2.0, w * 0.015)),
  );
  canvas.drawRRect(
    songketBand,
    Paint()
      ..color = songketBandColor
      ..isAntiAlias = true,
  );

  final eyePaint = Paint()
    ..color = eyeColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.0, w * 0.028)
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;
  final eyeFill = Paint()
    ..color = eyeColor
    ..isAntiAlias = true;

  final leftEyeX = cx - w * 0.08;
  final rightEyeX = cx + w * 0.08;
  final eyeY = h * 0.52;

  if (happyEyes) {
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(leftEyeX, eyeY),
        width: w * 0.07,
        height: w * 0.06,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(rightEyeX, eyeY),
        width: w * 0.07,
        height: w * 0.06,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );
  } else {
    canvas.drawCircle(Offset(leftEyeX, eyeY), w * 0.026, eyeFill);
    canvas.drawCircle(Offset(rightEyeX, eyeY), w * 0.026, eyeFill);
  }

  final mouthY = h * 0.60;
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(cx, mouthY - h * 0.01),
      width: w * 0.12,
      height: w * 0.08,
    ),
    0.15,
    math.pi - 0.3,
    false,
    eyePaint,
  );

  canvas.restore();
}

/// Paints a single-color monochrome silhouette of Si Rebung with transparent
/// facial cutouts (for Android 13+ themed icon and status-bar notifications).
void paintSiRebungMonochrome(
  Canvas canvas,
  Rect rect, {
  Color silhouetteColor = const Color(0xFFFFFFFF),
}) {
  canvas.saveLayer(rect, Paint());
  canvas.translate(rect.left, rect.top);
  final w = rect.width;
  final h = rect.height;
  final cx = w / 2;

  final fillPaint = Paint()
    ..color = silhouetteColor
    ..isAntiAlias = true;

  final bodyPath = Path()
    ..moveTo(cx, h * 0.16)
    ..quadraticBezierTo(w * 0.80, h * 0.45, w * 0.74, h * 0.84)
    ..quadraticBezierTo(cx, h * 0.92, w * 0.26, h * 0.84)
    ..quadraticBezierTo(w * 0.20, h * 0.45, cx, h * 0.16)
    ..close();
  canvas.drawPath(bodyPath, fillPaint);

  final tanjakPath = Path()
    ..moveTo(w * 0.22, h * 0.36)
    ..lineTo(w * 0.54, h * 0.11)
    ..lineTo(w * 0.79, h * 0.34)
    ..lineTo(w * 0.75, h * 0.42)
    ..lineTo(w * 0.25, h * 0.42)
    ..close();
  canvas.drawPath(tanjakPath, fillPaint);

  final clearStroke = Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.8, w * 0.038)
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;
  final clearFill = Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  // Cutout songket band line to separate tanjak from body.
  canvas.drawLine(
    Offset(w * 0.26, h * 0.39),
    Offset(w * 0.74, h * 0.39),
    clearStroke,
  );

  // Cutout eyes & smile.
  final leftEyeX = cx - w * 0.085;
  final rightEyeX = cx + w * 0.085;
  final eyeY = h * 0.53;
  canvas.drawCircle(
    Offset(leftEyeX, eyeY),
    math.max(1.2, w * 0.036),
    clearFill,
  );
  canvas.drawCircle(
    Offset(rightEyeX, eyeY),
    math.max(1.2, w * 0.036),
    clearFill,
  );

  final mouthY = h * 0.62;
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(cx, mouthY - h * 0.01),
      width: w * 0.15,
      height: w * 0.09,
    ),
    0.15,
    math.pi - 0.3,
    false,
    clearStroke,
  );

  // Cutout leaf lines at bottom.
  canvas.drawLine(
    Offset(w * 0.28, h * 0.66),
    Offset(cx, h * 0.85),
    clearStroke..strokeWidth = math.max(1.4, w * 0.026),
  );
  canvas.drawLine(
    Offset(w * 0.72, h * 0.66),
    Offset(cx, h * 0.85),
    clearStroke..strokeWidth = math.max(1.4, w * 0.026),
  );

  canvas.restore();
}

Future<void> writeCanvasPng({
  required String path,
  required int size,
  required void Function(Canvas canvas, double size) draw,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );
  draw(canvas, size.toDouble());
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData!.buffer.asUint8List(), flush: true);
}

void main() {
  test('Generates Si Rebung branding, launcher, splash, and notification PNGs', () async {
    // 1. Full 1024x1024 opaque launcher icon
    await writeCanvasPng(
      path: 'assets/branding/app_icon_1024.png',
      size: 1024,
      draw: (canvas, s) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, s, s),
          Paint()..color = const Color(0xFF0F5238),
        );
        canvas.drawCircle(
          Offset(s / 2, s * 0.52),
          s * 0.38,
          Paint()
            ..color = const Color(0xFFFFF8EC)
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          Offset(s / 2, s * 0.52),
          s * 0.38,
          Paint()
            ..color = const Color(0xFFF5B700)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.024
            ..isAntiAlias = true,
        );
        paintSiRebung(
          canvas,
          Rect.fromCenter(
            center: Offset(s / 2, s * 0.50),
            width: s * 0.72,
            height: s * 0.72,
          ),
        );
      },
    );

    // 2. Adaptive foreground 1024x1024 (strictly inside 66% safe zone)
    await writeCanvasPng(
      path: 'assets/branding/app_icon_foreground.png',
      size: 1024,
      draw: (canvas, s) {
        canvas.drawCircle(
          Offset(s / 2, s * 0.51),
          s * 0.27,
          Paint()
            ..color = const Color(0xFFFFF8EC)
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          Offset(s / 2, s * 0.51),
          s * 0.27,
          Paint()
            ..color = const Color(0xFFF5B700)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.016
            ..isAntiAlias = true,
        );
        paintSiRebung(
          canvas,
          Rect.fromCenter(
            center: Offset(s / 2, s * 0.50),
            width: s * 0.54,
            height: s * 0.54,
          ),
        );
      },
    );

    // 3. Adaptive monochrome 1024x1024 (Android 13+ themed icon, 66% safe zone)
    await writeCanvasPng(
      path: 'assets/branding/app_icon_monochrome.png',
      size: 1024,
      draw: (canvas, s) {
        paintSiRebungMonochrome(
          canvas,
          Rect.fromCenter(
            center: Offset(s / 2, s * 0.50),
            width: s * 0.54,
            height: s * 0.54,
          ),
        );
      },
    );

    // 4. Native splash center mascot 512x512
    await writeCanvasPng(
      path: 'assets/branding/splash_mascot.png',
      size: 512,
      draw: (canvas, s) {
        paintSiRebung(
          canvas,
          Rect.fromCenter(
            center: Offset(s / 2, s * 0.50),
            width: s * 0.76,
            height: s * 0.76,
          ),
          includeSoftCircle: true,
          softCircleColor: const Color(0xFFE2F5EC),
        );
      },
    );

    // 5. Android mipmap launcher icons (legacy + adaptive foreground + monochrome)
    const mipmapSpecs = [
      (folder: 'mipmap-mdpi', legacy: 48, adaptive: 108),
      (folder: 'mipmap-hdpi', legacy: 72, adaptive: 162),
      (folder: 'mipmap-xhdpi', legacy: 96, adaptive: 216),
      (folder: 'mipmap-xxhdpi', legacy: 144, adaptive: 324),
      (folder: 'mipmap-xxxhdpi', legacy: 192, adaptive: 432),
    ];

    for (final spec in mipmapSpecs) {
      final baseDir = 'android/app/src/main/res/${spec.folder}';
      await writeCanvasPng(
        path: '$baseDir/ic_launcher.png',
        size: spec.legacy,
        draw: (canvas, s) {
          final rrect = RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s, s),
            Radius.circular(s * 0.22),
          );
          canvas.drawRRect(
            rrect,
            Paint()
              ..color = const Color(0xFF0F5238)
              ..isAntiAlias = true,
          );
          canvas.drawCircle(
            Offset(s / 2, s * 0.52),
            s * 0.37,
            Paint()
              ..color = const Color(0xFFFFF8EC)
              ..isAntiAlias = true,
          );
          paintSiRebung(
            canvas,
            Rect.fromCenter(
              center: Offset(s / 2, s * 0.50),
              width: s * 0.74,
              height: s * 0.74,
            ),
          );
        },
      );

      await writeCanvasPng(
        path: '$baseDir/ic_launcher_foreground.png',
        size: spec.adaptive,
        draw: (canvas, s) {
          canvas.drawCircle(
            Offset(s / 2, s * 0.51),
            s * 0.27,
            Paint()
              ..color = const Color(0xFFFFF8EC)
              ..isAntiAlias = true,
          );
          canvas.drawCircle(
            Offset(s / 2, s * 0.51),
            s * 0.27,
            Paint()
              ..color = const Color(0xFFF5B700)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.016
              ..isAntiAlias = true,
          );
          paintSiRebung(
            canvas,
            Rect.fromCenter(
              center: Offset(s / 2, s * 0.50),
              width: s * 0.54,
              height: s * 0.54,
            ),
          );
        },
      );

      await writeCanvasPng(
        path: '$baseDir/ic_launcher_monochrome.png',
        size: spec.adaptive,
        draw: (canvas, s) {
          paintSiRebungMonochrome(
            canvas,
            Rect.fromCenter(
              center: Offset(s / 2, s * 0.50),
              width: s * 0.54,
              height: s * 0.54,
            ),
          );
        },
      );
    }

    // 6. Notification small icon (@drawable/ic_stat_katara) & splash mascot
    const drawableSpecs = [
      (folder: 'drawable', notif: 48, splash: 240),
      (folder: 'drawable-mdpi', notif: 24, splash: 120),
      (folder: 'drawable-hdpi', notif: 36, splash: 180),
      (folder: 'drawable-xhdpi', notif: 48, splash: 240),
      (folder: 'drawable-xxhdpi', notif: 72, splash: 360),
      (folder: 'drawable-xxxhdpi', notif: 96, splash: 480),
    ];

    for (final spec in drawableSpecs) {
      final baseDir = 'android/app/src/main/res/${spec.folder}';
      await writeCanvasPng(
        path: '$baseDir/ic_stat_katara.png',
        size: spec.notif,
        draw: (canvas, s) {
          paintSiRebungMonochrome(
            canvas,
            Rect.fromCenter(
              center: Offset(s / 2, s * 0.50),
              width: s * 0.88,
              height: s * 0.88,
            ),
          );
        },
      );

      await writeCanvasPng(
        path: '$baseDir/splash_mascot.png',
        size: spec.splash,
        draw: (canvas, s) {
          paintSiRebung(
            canvas,
            Rect.fromCenter(
              center: Offset(s / 2, s * 0.50),
              width: s * 0.76,
              height: s * 0.76,
            ),
            includeSoftCircle: true,
            softCircleColor: const Color(0xFFE2F5EC),
          );
        },
      );
    }
  });
}
