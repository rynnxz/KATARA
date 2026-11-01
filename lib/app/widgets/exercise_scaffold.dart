import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_progress_bar.dart';

enum ExerciseFeedbackState {
  none,
  correct,
  wrong,
}

/// Kerangka layar latihan: progress bar atas, indikator nyawa, tombol lapor, area soal,
/// serta bar umpan balik bawah yang tidak mengandalkan warna saja (ikon ✓ / ✗ + teks penjelasan).
class ExerciseScaffold extends StatelessWidget {
  const ExerciseScaffold({
    super.key,
    required this.progress,
    required this.hearts,
    required this.heartsEnabled,
    required this.feedbackState,
    required this.actionLabel,
    required this.onAction,
    required this.onClose,
    required this.child,
    this.feedbackTitle,
    this.feedbackDetail,
    this.onReportIssue,
    this.isActionEnabled = true,
  });

  final double progress;
  final int hearts;
  final bool heartsEnabled;
  final ExerciseFeedbackState feedbackState;
  final String? feedbackTitle;
  final String? feedbackDetail;
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;
  final VoidCallback? onReportIssue;
  final bool isActionEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = KataraPalette.of(context);

    final isCorrect = feedbackState == ExerciseFeedbackState.correct;
    final isWrong = feedbackState == ExerciseFeedbackState.wrong;
    final hasFeedback = isCorrect || isWrong;

    final bannerBg = isCorrect
        ? p.success.withValues(alpha: 0.16)
        : isWrong
            ? p.error.withValues(alpha: 0.16)
            : p.surface;
    final bannerBorder = isCorrect
        ? p.success
        : isWrong
            ? p.error
            : p.outline;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Keluar pelajaran',
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded, color: p.inkMuted),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: KProgressBar(
                      value: progress,
                      semanticLabel: 'Progres pelajaran',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        heartsEnabled
                            ? Icons.favorite_rounded
                            : Icons.spa_rounded,
                        size: 20,
                        color: heartsEnabled ? p.heart : p.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        heartsEnabled ? '$hearts' : 'Lv.1',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                  if (onReportIssue != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Laporkan kesalahan soal',
                      onPressed: onReportIssue,
                      icon: Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: p.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: child,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: bannerBg,
                border: Border(
                  top: BorderSide(color: bannerBorder, width: 2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasFeedback) ...[
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isCorrect ? p.success : p.error,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feedbackTitle ??
                                (isCorrect ? 'Jawaban Benar!' : 'Belum Tepat'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (feedbackDetail != null &&
                        feedbackDetail!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        feedbackDetail!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: p.ink,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  KButton(
                    label: actionLabel,
                    expand: true,
                    variant: isWrong
                        ? KButtonVariant.danger
                        : KButtonVariant.primary,
                    onPressed: isActionEnabled ? onAction : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
