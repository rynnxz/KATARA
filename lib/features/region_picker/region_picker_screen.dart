import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/k_progress_bar.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';

class RegionPickerScreen extends ConsumerWidget {
  const RegionPickerScreen({
    super.key,
    this.overrideLanguages,
    this.overrideCourses,
    this.overrideCourseCompletionRatio,
    this.onCourseSelected,
  });

  final List<LanguageModel>? overrideLanguages;
  final List<CourseModel>? overrideCourses;
  final Map<String, double>? overrideCourseCompletionRatio;
  final ValueChanged<CourseModel>? onCourseSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;

    if (overrideLanguages != null && overrideCourses != null) {
      return _RegionPickerContent(
        languages: overrideLanguages!,
        courses: overrideCourses!,
        completionRatios: overrideCourseCompletionRatio ?? const {},
        onSelectActiveCourse: (course) async {
          if (onCourseSelected != null) {
            onCourseSelected!(course);
          }
        },
      );
    }

    final languagesAsync = ref.watch(languagesProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Daerah Melayu'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: languagesAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: palette.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Gagal memuat daftar daerah: $err'),
            ),
          ),
          data: (languages) => coursesAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: palette.primary),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat daftar kursus: $err'),
              ),
            ),
            data: (courses) => _RegionPickerLoader(
              languages: languages,
              courses: courses,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionPickerLoader extends ConsumerWidget {
  const _RegionPickerLoader({
    required this.languages,
    required this.courses,
  });

  final List<LanguageModel> languages;
  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hitung rasio selesai untuk tiap course aktif.
    final activeCourse = courses.where((c) => c.isActive).firstOrNull;
    final unitsAsync = activeCourse != null
        ? ref.watch(courseUnitsProvider(activeCourse.id))
        : const AsyncValue<List<UnitModel>>.data([]);
    final progressAsync = activeCourse != null
        ? ref.watch(courseProgressStreamProvider(activeCourse.id))
        : const AsyncValue.data(<String, dynamic>{});

    final Map<String, double> ratios = {};
    if (activeCourse != null &&
        unitsAsync.hasValue &&
        progressAsync.hasValue) {
      final totalLessons = unitsAsync.value!
          .fold<int>(0, (sum, u) => sum + u.lessons.length);
      final completedLessons = progressAsync.value!.length;
      ratios[activeCourse.id] = totalLessons > 0
          ? (completedLessons / totalLessons).clamp(0.0, 1.0)
          : 0.0;
    }

    return _RegionPickerContent(
      languages: languages,
      courses: courses,
      completionRatios: ratios,
      onSelectActiveCourse: (course) async {
        await ref.read(progressRepositoryProvider).updateProfile(
              activeCourseId: course.id,
              onboardingCompleted: true,
            );
        if (!context.mounted) return;
        context.go('/home/learn');
      },
    );
  }
}

class _RegionPickerContent extends StatelessWidget {
  const _RegionPickerContent({
    required this.languages,
    required this.courses,
    required this.completionRatios,
    required this.onSelectActiveCourse,
  });

  final List<LanguageModel> languages;
  final List<CourseModel> courses;
  final Map<String, double> completionRatios;
  final Future<void> Function(CourseModel course) onSelectActiveCourse;

  void _showComingSoonSheet(BuildContext context, CourseModel course) {
    final palette = context.kataraPalette;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotView(state: MascotState.idle, size: 76),
            const SizedBox(height: 14),
            Text(
              '${course.name} Segera Hadir',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kurikulum daerah ini sedang disusun bersama penutur asli dan pemerhati budaya agar setiap kosakata terjamin keasliannya.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.inkMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            KButton(
              label: 'Mengerti',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const MascotView(state: MascotState.happy, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mau mulai dari daerah mana?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'XP, koin, dan streak berlaku di semua daerah. Kamu bebas berpindah kapan saja.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...languages.map((lang) {
          final langCourses =
              courses.where((c) => c.languageId == lang.id).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded, color: palette.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rumpun Bahasa: ${lang.name}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              lang.tagline,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...langCourses.map((course) {
                  final ratio = completionRatios[course.id] ?? 0.0;
                  final percent = (ratio * 100).round();
                  final isComingSoon = !course.isActive;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CourseTheme(
                      accentHex: course.accentHex,
                      isComingSoon: isComingSoon,
                      child: Builder(
                        builder: (courseCtx) {
                          final coursePalette = courseCtx.kataraPalette;
                          if (isComingSoon) {
                            return KCard(
                              backgroundColor:
                                  coursePalette.surfaceAlt.withValues(alpha: 0.7),
                              onTap: () =>
                                  _showComingSoonSheet(courseCtx, course),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: coursePalette.outline,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.lock_rounded,
                                      color: coursePalette.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.name,
                                          style: Theme.of(courseCtx)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: coursePalette.inkMuted,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          course.regionLabel,
                                          style: Theme.of(courseCtx)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: coursePalette.inkMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const KChip(
                                    label: 'Segera hadir',
                                    icon: Icons.schedule_rounded,
                                  ),
                                ],
                              ),
                            );
                          }

                          return KCard(
                            selected: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: coursePalette.secondary
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: coursePalette.secondary,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.auto_stories_rounded,
                                        color: coursePalette.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.name,
                                            style: Theme.of(courseCtx)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            course.regionLabel,
                                            style: Theme.of(courseCtx)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: coursePalette.inkMuted,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (course.hasJawi)
                                      KChip(
                                        label: 'Jawi + Rumi',
                                        backgroundColor: coursePalette.secondary
                                            .withValues(alpha: 0.22),
                                        textColor: coursePalette.ink,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progres Belajar',
                                      style: Theme.of(courseCtx)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              color: coursePalette.inkMuted),
                                    ),
                                    Text(
                                      '$percent% selesai',
                                      style: Theme.of(courseCtx)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: coursePalette.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                KProgressBar(
                                  value: ratio,
                                  height: 10,
                                  semanticLabel: 'Progres ${course.name}',
                                ),
                                const SizedBox(height: 16),
                                KButton(
                                  label: percent > 0 ? 'Lanjut' : 'Mulai',
                                  icon: Icons.play_arrow_rounded,
                                  onPressed: () => onSelectActiveCourse(course),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
