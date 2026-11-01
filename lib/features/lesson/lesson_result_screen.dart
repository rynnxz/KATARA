import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/app/widgets/result_burst.dart';

class LessonResultScreen extends ConsumerWidget {
  const LessonResultScreen({
    super.key,
    required this.lessonId,
  });

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final result = ref.watch(lastLessonResultProvider);

    final xpEarned = result?.xpEarned ?? 10;
    final stars = result?.stars ?? 3;
    final accuracyPercent = ((result?.accuracy ?? 1.0) * 100).round();
    final coinsEarned = result?.coinsEarned ?? 4;
    final newStreak = result?.newStreak ?? 1;
    final leveledUp = result?.leveledUp ?? false;
    final unlockedBadges = result?.newlyUnlockedAchievements ?? const [];

    return Scaffold(
      body: PatternBackground(
        opacity: 0.07,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        const MascotView(state: MascotState.cheer, size: 112),
                        const SizedBox(height: 16),
                        Text(
                          'Pelajaran Selesai!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Selangkah lebih dekat menjadi penutur Melayu Deli.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: palette.inkMuted,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        ResultBurst(
                          xpEarned: xpEarned,
                          stars: stars,
                          accuracyPercent: accuracyPercent,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: KCard(
                                child: Column(
                                  children: [
                                    Icon(Icons.track_changes_rounded,
                                        color: palette.success),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$accuracyPercent%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      'Akurasi',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: KCard(
                                child: Column(
                                  children: [
                                    Icon(Icons.monetization_on_rounded,
                                        color: palette.coin),
                                    const SizedBox(height: 6),
                                    Text(
                                      '+$coinsEarned',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      'Koin',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: KCard(
                                child: Column(
                                  children: [
                                    Icon(Icons.local_fire_department_rounded,
                                        color: palette.streak),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$newStreak hr',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      'Streak',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (unlockedBadges.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          KCard(
                            selected: true,
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded,
                                    color: palette.secondary, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Lencana baru terbuka (${unlockedBadges.length})! Cek di menu Misi.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                KButton(
                  label: leveledUp ? 'Lihat Kenaikan Level' : 'Kembali ke Peta',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (leveledUp) {
                      context.pushReplacement('/levelup');
                    } else {
                      context.go('/home/learn');
                    }
                  },
                ),
                const SizedBox(height: 10),
                KButton(
                  label: 'Ulangi Pelajaran',
                  variant: KButtonVariant.outline,
                  icon: Icons.replay_rounded,
                  onPressed: () =>
                      context.pushReplacement('/lesson/$lessonId'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
