import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

class ResultBurst extends StatefulWidget {
  const ResultBurst({
    super.key,
    required this.xpEarned,
    required this.stars,
    required this.accuracyPercent,
  });

  final int xpEarned;
  final int stars;
  final int accuracyPercent;

  @override
  State<ResultBurst> createState() => _ResultBurstState();
}

class _ResultBurstState extends State<ResultBurst> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!disableAnimations) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (!disableAnimations)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 16,
            colors: [p.primary, p.secondary, p.accent],
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final earned = index < widget.stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_border_rounded,
                    size: index == 1 ? 46 : 38,
                    color: earned ? p.secondary : p.outline,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<int>(
              tween: IntTween(
                begin: disableAnimations ? widget.xpEarned : 0,
                end: widget.xpEarned,
              ),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              builder: (context, val, _) {
                return Text(
                  '+$val XP',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Ketepatan ${widget.accuracyPercent}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
