import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/theme/katara_theme.dart';

/// Membungkus teks Aksara Jawi dengan `Directionality(textDirection: TextDirection.rtl)` (Bagian 10.3).
class JawiText extends StatelessWidget {
  const JawiText(
    this.text, {
    super.key,
    this.fontSize = 32,
    this.color,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final palette = KataraPalette.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign,
        style: KataraTypography.jawi(
          color: color ?? palette.ink,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
