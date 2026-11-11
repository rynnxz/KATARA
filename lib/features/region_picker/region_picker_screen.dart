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
import 'package:katara/services/module_download_service.dart';

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
        catalog: const [],
        completionRatios: overrideCourseCompletionRatio ?? const {},
        onSelectActiveCourse: (course) async {
          if (onCourseSelected != null) {
            onCourseSelected!(course);
          }
        },
        onDownloadModule: null,
        onUninstallModule: null,
        downloadingCourseId: null,
        downloadProgress: 0.0,
      );
    }

    final languagesAsync = ref.watch(languagesProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final catalogAsync = ref.watch(moduleCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Daerah & Modul Melayu'),
        actions: [
          IconButton(
            tooltip: 'Perbandingan Dialek',
            onPressed: () => context.push('/dialect-comparison'),
            icon: const Icon(Icons.compare_arrows_rounded),
          ),
        ],
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: languagesAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: palette.primary)),
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
              catalog: catalogAsync.value ?? const [],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionPickerLoader extends ConsumerStatefulWidget {
  const _RegionPickerLoader({
    required this.languages,
    required this.courses,
    required this.catalog,
  });

  final List<LanguageModel> languages;
  final List<CourseModel> courses;
  final List<ModuleCatalogItemModel> catalog;

  @override
  ConsumerState<_RegionPickerLoader> createState() =>
      _RegionPickerLoaderState();
}

class _RegionPickerLoaderState extends ConsumerState<_RegionPickerLoader> {
  String? _downloadingCourseId;
  double _downloadProgress = 0.0;
  final Map<String, int> _hashFailureCountByCourse = <String, int>{};

  Future<void> _handleDownload(CourseModel course) async {
    final catalogItem =
        widget.catalog.where((m) => m.courseId == course.id).firstOrNull ??
        ModuleCatalogItemModel(
          id: course.dialectId,
          courseId: course.id,
          name: course.name,
          regionLabel: course.regionLabel,
          version: course.contentVersion > 0 ? course.contentVersion : 2,
          isBundled: false,
          accentHex: course.accentHex,
          archiveFilename: course.id == 'ms-langkat'
              ? 'module_langkat.zip'
              : 'module_palembang.zip',
          downloadUrl: course.downloadUrl,
          sha256: course.sha256,
          sizeBytes: course.sizeBytes > 0 ? course.sizeBytes : 71391,
          vocabularyCount: 308,
          lessonCount: 64,
          quizCount: 110,
        );

    setState(() {
      _downloadingCourseId = course.id;
      _downloadProgress = 0.1;
    });

    try {
      await ref
          .read(moduleDownloadServiceProvider)
          .installModule(
            catalogItem,
            onProgress: (p) {
              if (mounted) {
                setState(() => _downloadProgress = p);
              }
            },
          );
      _hashFailureCountByCourse.remove(course.id);
      ref.invalidate(coursesProvider);
      ref.invalidate(installedModulesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Modul ${course.name} berhasil dipasang dan diverifikasi (SHA-256)!',
          ),
        ),
      );
    } catch (e) {
      ModuleDownloadErrorMapper.logDebug(
        e,
        context: 'RegionPicker:${course.id}',
      );
      if (!mounted) return;
      final isHashError = ModuleDownloadErrorMapper.isSecurityHashFailure(e);
      final attemptCount = isHashError
          ? ((_hashFailureCountByCourse[course.id] ?? 0) + 1)
          : 1;
      if (isHashError) {
        _hashFailureCountByCourse[course.id] = attemptCount;
      }
      final friendlyMessage = ModuleDownloadErrorMapper.toUserMessage(
        e,
        courseName: course.name,
        attemptCount: attemptCount,
      );
      final allowRetry = ModuleDownloadErrorMapper.canRetry(
        e,
        attemptCount: attemptCount,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          action: allowRetry
              ? SnackBarAction(
                  label: 'Coba Lagi',
                  onPressed: () => _handleDownload(course),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingCourseId = null;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _handleUninstall(CourseModel course) async {
    try {
      await ref.read(moduleDownloadServiceProvider).uninstallModule(course.id);
      ref.invalidate(coursesProvider);
      ref.invalidate(installedModulesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berkas modul ${course.name} dihapus. Progres XP & bintang tetap tersimpan.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final friendlyMessage = ModuleDownloadErrorMapper.toUserMessage(
        e,
        courseName: course.name,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> ratios = {};
    for (final c in widget.courses.where((c) => c.isActive)) {
      final unitsAsync = ref.watch(courseUnitsProvider(c.id));
      final progressAsync = ref.watch(courseProgressStreamProvider(c.id));
      if (unitsAsync.hasValue && progressAsync.hasValue) {
        final totalLessons = unitsAsync.value!.fold<int>(
          0,
          (sum, u) => sum + u.lessons.length,
        );
        final completedLessons = progressAsync.value!.length;
        ratios[c.id] = totalLessons > 0
            ? (completedLessons / totalLessons).clamp(0.0, 1.0)
            : 0.0;
      }
    }

    return _RegionPickerContent(
      languages: widget.languages,
      courses: widget.courses,
      catalog: widget.catalog,
      completionRatios: ratios,
      downloadingCourseId: _downloadingCourseId,
      downloadProgress: _downloadProgress,
      onDownloadModule: _handleDownload,
      onUninstallModule: _handleUninstall,
      onSelectActiveCourse: (course) async {
        await ref
            .read(progressRepositoryProvider)
            .updateProfile(
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
    required this.catalog,
    required this.completionRatios,
    required this.onSelectActiveCourse,
    required this.onDownloadModule,
    required this.onUninstallModule,
    required this.downloadingCourseId,
    required this.downloadProgress,
  });

  final List<LanguageModel> languages;
  final List<CourseModel> courses;
  final List<ModuleCatalogItemModel> catalog;
  final Map<String, double> completionRatios;
  final Future<void> Function(CourseModel course) onSelectActiveCourse;
  final Future<void> Function(CourseModel course)? onDownloadModule;
  final Future<void> Function(CourseModel course)? onUninstallModule;
  final String? downloadingCourseId;
  final double downloadProgress;

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
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: palette.inkMuted),
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
                    'Melayu Deli sudah terpasang bawaan. Modul Melayu Langkat & Palembang dapat diunduh terpisah agar ukuran aplikasi tetap hemat.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...languages.map((lang) {
          final langCourses = courses
              .where((c) => c.languageId == lang.id)
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              lang.tagline,
                              style: Theme.of(context).textTheme.labelMedium
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
                  final isDownloadable =
                      course.isDownloadable && !course.isActive;
                  final isComingSoon =
                      course.status == 'coming_soon' && !course.isDownloadable;
                  final identity = DialectVisualIdentity.forCourse(course.id);
                  final sizeKb = course.sizeBytes > 0
                      ? (course.sizeBytes / 1024).round()
                      : 81;
                  final isDownloading = downloadingCourseId == course.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CourseTheme(
                      accentHex: course.accentHex,
                      courseId: course.id,
                      isComingSoon: isComingSoon,
                      child: Builder(
                        builder: (courseCtx) {
                          final coursePalette = courseCtx.kataraPalette;

                          if (isComingSoon) {
                            return KCard(
                              backgroundColor: coursePalette.surfaceAlt,
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
                                                color: coursePalette.ink,
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

                          if (isDownloadable) {
                            return KCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: identity.badgeBgLight,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: identity.accentColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.cloud_download_rounded,
                                          color: identity.badgeFgLight,
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
                                                    color:
                                                        coursePalette.inkMuted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Motif Budaya: ${identity.motifName} • 300+ kosakata, 10 percakapan, 110 soal kuis.',
                                    style: Theme.of(courseCtx)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: coursePalette.inkMuted,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      DialectIdentityBadge(
                                        courseId: course.id,
                                        labelOverride: identity.motifName,
                                      ),
                                      KChip(
                                        label: 'Ukuran ~$sizeKb KB',
                                        icon: Icons.folder_zip_rounded,
                                      ),
                                      const KChip(
                                        label: 'Cek SHA-256 saat pasang',
                                        icon: Icons.shield_outlined,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (isDownloading) ...[
                                    KProgressBar(
                                      value: downloadProgress,
                                      height: 10,
                                      semanticLabel:
                                          'Mengunduh modul ${course.name}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      downloadProgress < 0.65
                                          ? 'Mengunduh paket modul (${(downloadProgress * 100).round()}%)...'
                                          : 'Memverifikasi SHA-256 & memasang modul...',
                                      style: Theme.of(courseCtx)
                                          .textTheme
                                          .labelSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ] else
                                    KButton(
                                      label:
                                          'Unduh Modul ${course.name} ($sizeKb KB)',
                                      icon: Icons.download_rounded,
                                      onPressed: onDownloadModule != null
                                          ? () => onDownloadModule!(course)
                                          : null,
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
                                        color: identity.badgeBgLight,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: identity.accentColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.auto_stories_rounded,
                                        color: identity.badgeFgLight,
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
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (course.isBundled)
                                      const KChip(
                                        label: 'Bawaan',
                                        icon: Icons.offline_pin_rounded,
                                      )
                                    else if (onUninstallModule != null)
                                      IconButton(
                                        tooltip:
                                            'Hapus berkas modul ${course.name}',
                                        onPressed: () =>
                                            onUninstallModule!(course),
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: coursePalette.error,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    DialectIdentityBadge(
                                      courseId: course.id,
                                      labelOverride: identity.motifName,
                                    ),
                                    if (!course.isBundled)
                                      const KChip(
                                        label:
                                            'Terpasang • SHA-256 Terverifikasi',
                                        icon: Icons.verified_user_rounded,
                                      ),
                                    if (course.hasJawi)
                                      const KChip(
                                        label: 'Jawi + Rumi',
                                        icon: Icons.translate_rounded,
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
                                            color: coursePalette.inkMuted,
                                          ),
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
