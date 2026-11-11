import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/jawi_text.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/app/widgets/report_issue_dialog.dart';
import 'package:katara/data/content/content_models.dart';

class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({
    super.key,
    required this.unitId,
  });

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final contentRepo = ref.watch(contentRepositoryProvider);
    final showJawi = ref.watch(appSettingsProvider).showJawiScript;

    return FutureBuilder<(UnitModel?, List<WordModel>, List<PhraseModel>)>(
      future: () async {
        final unit = await contentRepo.getUnit(unitId);
        if (unit == null) {
          return (null, <WordModel>[], <PhraseModel>[]);
        }
        final allWords = await contentRepo.getWords(unit.courseId);
        final allPhrases = await contentRepo.getPhrases(unit.courseId);
        final Set<String> refs = {
          for (final l in unit.lessons) ...l.itemRefs,
        };
        final unitWords = allWords
            .where((w) => refs.contains(w.id) || w.unitId == unit.id)
            .toList();
        final unitPhrases =
            allPhrases.where((p) => refs.contains(p.id)).toList();
        return (unit, unitWords, unitPhrases);
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ringkasan Unit')),
            body: Center(
              child: CircularProgressIndicator(color: palette.primary),
            ),
          );
        }

        final data = snapshot.data;
        final unit = data?.$1;
        if (unit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ringkasan Unit')),
            body: const Center(child: Text('Unit tidak ditemukan.')),
          );
        }

        final words = data!.$2;
        final phrases = data.$3;
        final firstLesson = unit.lessons.firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text('Unit ${unit.order}: ${unit.title}'),
          ),
          body: PatternBackground(
            opacity: 0.05,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                KCard(
                  selected: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          KChip(
                            label: 'Level ${unit.level}',
                            backgroundColor: palette.secondaryContainer,
                            textColor: palette.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          KChip(
                            label: '${unit.lessons.length} pelajaran',
                            icon: Icons.menu_book_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        unit.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: palette.onPrimaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unit.theme,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.onPrimaryContainer,
                            ),
                      ),
                      if (firstLesson != null) ...[
                        const SizedBox(height: 16),
                        KButton(
                          label: 'Mulai Pelajaran Pertama',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () =>
                              context.push('/lesson/${firstLesson.id}'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Daftar Pelajaran',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...unit.lessons.map((lesson) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: KCard(
                      onTap: () => context.push('/lesson/${lesson.id}'),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: palette.primaryContainer,
                            foregroundColor: palette.onPrimaryContainer,
                            child: Text(
                              '${lesson.order}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Hadiah dasar: +${lesson.xpReward} XP',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: palette.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text(
                  'Kosakata & Ungkapan di Unit Ini (${words.length + phrases.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...words.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        w.deli,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: palette.primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      ValidationStatusBadge(
                                          status: w.validationStatus),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    w.indonesia,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (w.register == 'baku')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Ragam baku Melayu (cek pemakaian harian di Deli)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                                color: palette.inkMuted),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (showJawi && w.jawi != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: JawiText(w.jawi!, fontSize: 26),
                              ),
                            IconButton(
                              tooltip: 'Laporkan kesalahan',
                              onPressed: () => showReportIssueSheet(
                                context,
                                ref,
                                courseId: unit.courseId,
                                itemId: w.id,
                                itemType: 'word',
                                itemTitle: '${w.deli} (${w.indonesia})',
                              ),
                              icon: Icon(
                                Icons.flag_outlined,
                                size: 20,
                                color: palette.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                ...phrases.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.deli,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: palette.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                ValidationStatusBadge(
                                    status: p.validationStatus),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.indonesia,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (p.culturalNote != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                p.culturalNote!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: palette.inkMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
