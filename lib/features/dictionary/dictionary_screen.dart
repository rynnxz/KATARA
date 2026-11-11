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
import 'package:katara/domain/entities/user_progress.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'semua';

  static const List<(String, String)> _categories = [
    ('semua', 'Semua'),
    ('sapaan', 'Sapaan'),
    ('keluarga', 'Keluarga'),
    ('angka', 'Angka'),
    ('makanan', 'Makanan'),
    ('sifat', 'Sifat'),
    ('kerja', 'Kata Kerja'),
    ('pronomina_tanya', 'Pronomina & Tanya'),
    ('waktu_arah', 'Waktu & Arah'),
    ('tempat_benda', 'Tempat & Benda'),
    ('perasaan', 'Perasaan'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showWordDetailSheet(
    BuildContext context,
    WordModel word,
    WordMastery? mastery,
    bool showJawi,
  ) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ValidationStatusBadge(status: word.validationStatus),
                const SizedBox(width: 8),
                KChip(
                  label: 'Level ${word.level} • ${word.pos}',
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.deli,
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: palette.primary,
                                ),
                      ),
                      if (word.pronunciation != null &&
                          word.pronunciation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '[${word.pronunciation}] • Ragam ${word.rawRegister}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: palette.inkMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        word.indonesia,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                if (showJawi && word.jawi != null)
                  JawiText(
                    word.jawi!,
                    fontSize: 38,
                    color: palette.primary,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (word.exampleSentence != null &&
                word.exampleSentence!.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contoh Kalimat:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${word.exampleSentence}"',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (word.exampleTranslation != null &&
                        word.exampleTranslation!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        word.exampleTranslation!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (word.sources.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (word.region != null && word.region!.isNotEmpty)
                    KChip(
                      label: word.region!,
                      icon: Icons.place_outlined,
                    ),
                  for (final src in word.sources)
                    KChip(
                      label: 'Sumber: $src',
                      icon: Icons.menu_book_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (word.userFacingNotes != null &&
                word.userFacingNotes!.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.outline),
                ),
                child: Text(
                  word.userFacingNotes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (word.register == 'baku')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Catatan ragam: Kata ini tercatat sebagai kosakata Melayu baku dalam draf awal dan sedang diverifikasi pemakaian hariannya oleh penutur Melayu Deli.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.inkMuted,
                      ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: palette.secondary, size: 20),
                const SizedBox(width: 6),
                Text(
                  mastery != null
                      ? 'Penguasaan: Kekuatan ${mastery.strength}/5 (${mastery.correctCount} benar)'
                      : 'Penguasaan: Belum dilatih di pelajaran',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.inkMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            KButton(
              label: 'Laporkan Kesalahan Kata Ini',
              variant: KButtonVariant.outline,
              icon: Icons.flag_outlined,
              onPressed: () {
                Navigator.of(ctx).pop();
                showReportIssueSheet(
                  context,
                  ref,
                  courseId: word.courseId,
                  itemId: word.id,
                  itemType: 'word',
                  itemTitle: '${word.deli} (${word.indonesia})',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final showJawi = ref.watch(appSettingsProvider).showJawiScript;
    final statsAsync = ref.watch(userStatsStreamProvider);
    final courseId = statsAsync.value?.activeCourseId ?? 'ms-deli';
    final activeCourse = ref.watch(activeCourseProvider).value;
    final courseTitle = activeCourse?.name ?? 'Melayu Deli';

    return Scaffold(
      appBar: AppBar(
        title: Text('Kamus $courseTitle'),
        actions: [
          IconButton(
            tooltip: 'Perbandingan Dialek',
            onPressed: () => context.push('/dialect-comparison'),
            icon: const Icon(Icons.compare_arrows_rounded),
          ),
        ],
      ),
      body: PatternBackground(
        opacity: 0.04,
        courseId: courseId,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari kata Deli atau arti Indonesia...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded),
                        )
                      : null,
                  filled: true,
                  fillColor: palette.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.outline),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: KChip(
                      label: cat.$2,
                      selected: isSelected,
                      onTap: () => setState(() => _selectedCategory = cat.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder<(List<WordModel>, Map<String, WordMastery>)>(
                future: () async {
                  final words = await ref
                      .read(contentRepositoryProvider)
                      .getWords(
                        courseId,
                        category: _selectedCategory,
                        query: _searchController.text,
                      );
                  final masteryList = await ref
                      .read(progressRepositoryProvider)
                      .getCourseMastery(courseId);
                  final map = {for (final m in masteryList) m.itemId: m};
                  return (words, map);
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child:
                          CircularProgressIndicator(color: palette.primary),
                    );
                  }
                  final words = snapshot.data?.$1 ?? const [];
                  final masteryMap = snapshot.data?.$2 ?? const {};

                  if (words.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Tidak ada kata yang cocok dengan pencarianmu.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: palette.inkMuted,
                                  ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final w = words[index];
                      final mastery = masteryMap[w.id];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: KCard(
                          onTap: () => _showWordDetailSheet(
                            context,
                            w,
                            mastery,
                            showJawi,
                          ),
                          child: Row(
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
                                          status: w.validationStatus,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      w.indonesia,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              if (showJawi && w.jawi != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: JawiText(w.jawi!, fontSize: 26),
                                ),
                              if (mastery != null)
                                KChip(
                                  label: '${mastery.strength}/5',
                                  icon: Icons.star_rounded,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
