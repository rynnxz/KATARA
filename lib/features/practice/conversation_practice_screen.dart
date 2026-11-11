import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';

class ConversationPracticeScreen extends ConsumerStatefulWidget {
  const ConversationPracticeScreen({super.key});

  @override
  ConsumerState<ConversationPracticeScreen> createState() =>
      _ConversationPracticeScreenState();
}

class _ConversationPracticeScreenState
    extends ConsumerState<ConversationPracticeScreen> {
  DialogueModel? _selectedDialogue;
  int _visibleLineCount = 1;
  bool _showTranslations = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);
    final courseId = statsAsync.value?.activeCourseId ?? 'ms-deli';

    if (_selectedDialogue != null) {
      return _buildDialogueSession(context, palette, _selectedDialogue!, courseId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Percakapan Kontekstual'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        courseId: courseId,
        child: FutureBuilder<List<DialogueModel>>(
          future: ref.read(contentRepositoryProvider).getDialogues(courseId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: palette.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat percakapan: ${snapshot.error}'),
                ),
              );
            }
            final dialogues = snapshot.data ?? const [];
            if (dialogues.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Belum ada percakapan untuk dialek ini.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.inkMuted,
                        ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: dialogues.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: KCard(
                      backgroundColor: palette.surfaceAlt,
                      child: Row(
                        children: [
                          Icon(Icons.forum_rounded,
                              color: palette.primary, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Simulasi Dialog Sehari-hari',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pelajari alur sapaan, intonasi, dan adab bertutur dalam situasi nyata masyarakat Melayu.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final d = dialogues[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KCard(
                    onTap: () {
                      setState(() {
                        _selectedDialogue = d;
                        _visibleLineCount = 1;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$index',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: palette.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${d.lines.length} giliran tutur • Level ${d.level}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: palette.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogueSession(
    BuildContext context,
    KataraPalette palette,
    DialogueModel dialogue,
    String courseId,
  ) {
    final visibleLines = dialogue.lines.take(_visibleLineCount).toList();
    final isComplete = _visibleLineCount >= dialogue.lines.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(dialogue.title),
        leading: IconButton(
          tooltip: 'Kembali ke daftar dialog',
          onPressed: () => setState(() => _selectedDialogue = null),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: KChip(
                label: _showTranslations ? 'Sembunyikan Arti' : 'Tampilkan Arti',
                icon: Icons.translate_rounded,
                onTap: () =>
                    setState(() => _showTranslations = !_showTranslations),
              ),
            ),
          ),
        ],
      ),
      body: PatternBackground(
        opacity: 0.04,
        courseId: courseId,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: visibleLines.length,
                itemBuilder: (context, idx) {
                  final line = visibleLines[idx];
                  final isLeft = idx.isEven;
                  return Align(
                    alignment:
                        isLeft ? Alignment.centerLeft : Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: KCard(
                          backgroundColor:
                              isLeft ? palette.surface : palette.surfaceAlt,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    line.speaker,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: palette.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    '#${line.order}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: palette.inkMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                line.deli,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (_showTranslations) ...[
                                const SizedBox(height: 6),
                                Text(
                                  line.indonesia,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.outline)),
              ),
              child: SafeArea(
                top: false,
                child: KButton(
                  label: isComplete
                      ? 'Selesai & Klaim +10 XP'
                      : 'Lanjut Giliran Berikutnya ($_visibleLineCount/${dialogue.lines.length})',
                  icon: isComplete
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: () async {
                    if (!isComplete) {
                      setState(() => _visibleLineCount++);
                      return;
                    }
                    await ref
                        .read(progressRepositoryProvider)
                        .recordPracticeReview(
                          courseId: courseId,
                          outcomes: const [],
                          xpEarned: 10,
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Dialog selesai dipelajari! +10 XP berhasil ditambahkan.',
                        ),
                      ),
                    );
                    setState(() => _selectedDialogue = null);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
