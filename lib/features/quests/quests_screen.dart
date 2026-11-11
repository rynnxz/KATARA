import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/k_progress_bar.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/domain/entities/user_progress.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  Future<void> _claimQuest(String questId) async {
    final coins =
        await ref.read(progressRepositoryProvider).claimQuestReward(questId);
    if (!mounted) return;
    setState(() {});
    if (coins > 0) {
      await ref.read(sfxServiceProvider).playCorrect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hadiah misi diklaim: +$coins Koin!')),
      );
    }
  }

  Future<void> _claimChest() async {
    final coins =
        await ref.read(progressRepositoryProvider).claimDailyChest();
    if (!mounted) return;
    setState(() {});
    if (coins != null) {
      await ref.read(sfxServiceProvider).playLessonComplete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Peti Harian dibuka! Kamu mendapat +$coins Koin & +20 XP!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misi Harian & Lencana'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: FutureBuilder<
            (
              List<DailyQuestProgress>,
              bool,
              List<AchievementModel>,
            )>(
          future: () async {
            final progressRepo = ref.read(progressRepositoryProvider);
            final contentRepo = ref.read(contentRepositoryProvider);
            final quests = await progressRepo.getDailyQuests();
            final chestClaimed = await progressRepo.isDailyChestClaimedToday();
            final unlockedIds = await progressRepo.getUnlockedAchievements();
            final achievements = await contentRepo.getAchievements(
              unlockedIds: unlockedIds,
            );
            return (quests, chestClaimed, achievements);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: palette.primary),
              );
            }

            final quests = snapshot.data?.$1 ?? const [];
            final chestClaimed = snapshot.data?.$2 ?? false;
            final achievements = snapshot.data?.$3 ?? const [];
            final allCompleted =
                quests.isNotEmpty && quests.every((q) => q.isCompleted);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                KCard(
                  selected: allCompleted && !chestClaimed,
                  child: Row(
                    children: [
                      const MascotView(state: MascotState.cheer, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Peti Hadiah Harian',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chestClaimed
                                  ? 'Peti hari ini sudah dibuka. Kembali lagi besok!'
                                  : 'Selesaikan ketiga misi harian untuk membuka peti berisi +20 XP dan koin acak.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                            if (allCompleted && !chestClaimed) ...[
                              const SizedBox(height: 12),
                              KButton(
                                label: 'Buka Peti Harian',
                                icon: Icons.redeem_rounded,
                                onPressed: _claimChest,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Misi Hari Ini',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...quests.map((q) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  q.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              KChip(
                                label: '+${q.rewardCoins} Koin',
                                icon: Icons.monetization_on_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: KProgressBar(
                                  value: q.ratio,
                                  height: 10,
                                  semanticLabel: q.title,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${q.progress}/${q.target}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          if (q.isCompleted && !q.claimed) ...[
                            const SizedBox(height: 12),
                            KButton(
                              label: 'Klaim +${q.rewardCoins} Koin',
                              variant: KButtonVariant.secondary,
                              onPressed: () => _claimQuest(q.questId),
                            ),
                          ] else if (q.claimed) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: palette.success, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Hadiah sudah diklaim',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: palette.success),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Text(
                  'Lencana Pencapaian (${achievements.where((a) => a.unlocked).length}/${achievements.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...achievements.map((badge) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KCard(
                      selected: badge.unlocked,
                      backgroundColor: badge.unlocked
                          ? palette.surface
                          : palette.surfaceAlt,
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: badge.unlocked
                                  ? palette.secondaryContainer
                                  : palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: palette.outline),
                            ),
                            child: Icon(
                              badge.unlocked
                                  ? Icons.workspace_premium_rounded
                                  : Icons.lock_outline_rounded,
                              color: badge.unlocked
                                  ? palette.onSecondaryContainer
                                  : palette.inkMuted,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  badge.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: badge.unlocked
                                            ? palette.ink
                                            : palette.inkMuted,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  badge.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          KChip(
                            label: badge.unlocked
                                ? 'Terbuka'
                                : '+${badge.rewardCoins} Koin',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
