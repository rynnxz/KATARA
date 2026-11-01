import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/k_header_stats.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/path_node.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/domain/entities/user_progress.dart';

class LearnMapScreen extends ConsumerWidget {
  const LearnMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);
    final activeCourseAsync = ref.watch(activeCourseProvider);

    return statsAsync.when(
      loading: () => Scaffold(
        body: Center(child: CircularProgressIndicator(color: palette.primary)),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Gagal memuat profil: $err')),
      ),
      data: (stats) => activeCourseAsync.when(
        loading: () => Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: palette.primary)),
        ),
        error: (err, _) => Scaffold(
          body: Center(child: Text('Gagal memuat daerah aktif: $err')),
        ),
        data: (course) {
          if (course == null) {
            return Scaffold(
              body: Center(
                child: KButton(
                  label: 'Pilih Daerah',
                  onPressed: () => context.push('/region'),
                ),
              ),
            );
          }

          return CourseTheme(
            accentHex: course.accentHex,
            child: _LearnMapBody(stats: stats, course: course),
          );
        },
      ),
    );
  }
}

class _LearnMapBody extends ConsumerWidget {
  const _LearnMapBody({
    required this.stats,
    required this.course,
  });

  final UserStats stats;
  final CourseModel course;

  IconData _iconForLessonKind(String kind) {
    return switch (kind) {
      'vocab' => Icons.menu_book_rounded,
      'phrase' => Icons.chat_bubble_rounded,
      'jawi' => Icons.translate_rounded,
      'dialogue' => Icons.forum_rounded,
      'culture' => Icons.account_balance_rounded,
      'review' => Icons.replay_rounded,
      'boss' => Icons.workspace_premium_rounded,
      _ => Icons.menu_book_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final unitsAsync = ref.watch(courseUnitsProvider(course.id));
    final progressAsync = ref.watch(courseProgressStreamProvider(course.id));
    final heartsEnabled = !stats.casualMode && stats.level >= 2;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: KHeaderStats(
                streak: stats.streakCurrent,
                coins: stats.coins,
                hearts: stats.hearts,
                xp: stats.xpTotal,
                heartsEnabled: heartsEnabled,
                regionLabel: course.name,
                onRegionTap: () => context.push('/region'),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              border: Border(bottom: BorderSide(color: palette.outline)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  KChip(
                    label: 'Kamus Deli',
                    icon: Icons.search_rounded,
                    onTap: () => context.push('/dictionary'),
                  ),
                  const SizedBox(width: 8),
                  if (course.hasJawi) ...[
                    KChip(
                      label: 'Aksara Jawi',
                      icon: Icons.auto_stories_rounded,
                      onTap: () => context.push('/jawi'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  KChip(
                    label: 'Toko Koin',
                    icon: Icons.storefront_rounded,
                    onTap: () => context.push('/shop'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(width: 8),
                    KChip(
                      label: 'Dev Gallery',
                      icon: Icons.developer_mode_rounded,
                      onTap: () => context.push('/dev/gallery'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: PatternBackground(
              opacity: 0.05,
              child: unitsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: palette.primary),
                ),
                error: (err, _) => Center(
                  child: Text('Gagal memuat unit: $err'),
                ),
                data: (units) => progressAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: palette.primary),
                  ),
                  error: (err, _) => Center(
                    child: Text('Gagal memuat progres: $err'),
                  ),
                  data: (progressMap) => _buildUnitsList(
                    context,
                    palette,
                    units,
                    progressMap,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(
    BuildContext context,
    KataraPalette palette,
    List<UnitModel> units,
    Map<String, CourseProgress> progressMap,
  ) {
    // Tentukan pelajaran aktif berikutnya (pertama yang belum selesai).
    LessonModel? nextActiveLesson;
    UnitModel? nextActiveUnit;
    final Set<String> unlockedLessonIds = {};
    bool previousCompleted = true;

    for (final unit in units) {
      for (final lesson in unit.lessons) {
        final isCompleted = progressMap.containsKey(lesson.id);
        if (previousCompleted || isCompleted) {
          unlockedLessonIds.add(lesson.id);
        }
        if (!isCompleted && nextActiveLesson == null && previousCompleted) {
          nextActiveLesson = lesson;
          nextActiveUnit = unit;
        }
        previousCompleted = isCompleted;
      }
    }

    // Jika semua selesai, pelajaran aktif default ke pelajaran pertama.
    if (nextActiveLesson == null &&
        units.isNotEmpty &&
        units.first.lessons.isNotEmpty) {
      nextActiveUnit = units.first;
      nextActiveLesson = units.first.lessons.first;
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      itemCount: units.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          if (nextActiveLesson == null || nextActiveUnit == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: KCard(
              selected: true,
              child: Row(
                children: [
                  const MascotView(state: MascotState.cheer, size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langkah Berikutnya',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nextActiveUnit.title} • ${nextActiveLesson.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        KButton(
                          label: 'Lanjut Belajar',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () =>
                              context.push('/lesson/${nextActiveLesson!.id}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final unit = units[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/unit/${unit.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primaryDark,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNIT ${unit.order} • LEVEL ${unit.level}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: palette.onPrimary
                                        .withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unit.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: palette.onPrimary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unit.theme,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: palette.onPrimary
                                        .withValues(alpha: 0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primaryDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              color: palette.onPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ringkasan',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: palette.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(unit.lessons.length, (lessonIdx) {
                final lesson = unit.lessons[lessonIdx];
                final progress = progressMap[lesson.id];
                final isCompleted = progress != null;
                final isUnlocked = unlockedLessonIds.contains(lesson.id);
                final isBoss = lesson.kind == 'boss';

                final PathNodeStatus nodeState;
                if (isCompleted) {
                  nodeState = PathNodeStatus.completed;
                } else if (isUnlocked) {
                  nodeState =
                      isBoss ? PathNodeStatus.boss : PathNodeStatus.active;
                } else {
                  nodeState = PathNodeStatus.locked;
                }

                // Pola berkelok (winding path) dengan offset horizontal ringan.
                final double horizontalOffset = switch (lessonIdx % 4) {
                  1 => 36.0,
                  3 => -36.0,
                  _ => 0.0,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(horizontalOffset, 0),
                      child: PathNode(
                        title: lesson.title,
                        status: nodeState,
                        stars: progress?.stars ?? 0,
                        icon: _iconForLessonKind(lesson.kind),
                        onTap: isUnlocked
                            ? () => context.push('/lesson/${lesson.id}')
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Selesaikan pelajaran sebelumnya untuk membuka langkah ini.',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
