import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/jawi_text.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';

class JawiScreen extends ConsumerWidget {
  const JawiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);
    final courseId = statsAsync.value?.activeCourseId ?? 'ms-deli';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aksara Jawi Melayu'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: FutureBuilder<List<JawiLetterModel>>(
          future: ref.read(contentRepositoryProvider).getLetters(courseId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: palette.primary),
              );
            }

            final letters = snapshot.data ?? const [];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                KCard(
                  selected: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const MascotView(state: MascotState.cheer, size: 64),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '6 Huruf Tambahan Jawi Melayu',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Aksara Jawi ditulis dari kanan ke kiri (RTL) dan memiliki 6 huruf khusus untuk bunyi bahasa Melayu yang tidak ada dalam abjad Arab standar.',
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
                      const SizedBox(height: 16),
                      KButton(
                        label: 'Latihan Pelajaran Jawi',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () =>
                            context.push('/lesson/ms-deli:l:0011'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Daftar Huruf & Aturan Sambung',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...letters.map((letter) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: KCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      palette.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: palette.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: JawiText(
                                  letter.glyph,
                                  fontSize: 34,
                                  color: palette.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Huruf ${letter.name.toUpperCase()}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        const SizedBox(width: 8),
                                        ValidationStatusBadge(
                                          status: letter.validationStatus,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bunyi Latin: "${letter.sound}"',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (letter.arabicBase != null)
                                      Text(
                                        'Basis huruf: ${letter.arabicBase} (${letter.dots ?? ""})',
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
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _FormCell(
                                  label: 'Tunggal',
                                  glyph: letter.forms['isolated'] ?? letter.glyph,
                                ),
                                _FormCell(
                                  label: 'Awal',
                                  glyph: letter.forms['initial'] ?? letter.glyph,
                                ),
                                _FormCell(
                                  label: 'Tengah',
                                  glyph: letter.forms['medial'] ?? letter.glyph,
                                ),
                                _FormCell(
                                  label: 'Akhir',
                                  glyph: letter.forms['final'] ?? letter.glyph,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              KChip(
                                label: letter.connectsToNext
                                    ? 'Menyambung ke huruf sesudahnya'
                                    : 'Tidak menyambung ke kiri',
                                icon: letter.connectsToNext
                                    ? Icons.link_rounded
                                    : Icons.link_off_rounded,
                              ),
                              if (letter.exampleWordLatin != null)
                                KChip(
                                  label:
                                      'Contoh: ${letter.exampleWordLatin} (${letter.exampleMeaningId ?? ""})',
                                ),
                              if (letter.exampleWordJawi != null)
                                JawiText(
                                  letter.exampleWordJawi!,
                                  fontSize: 24,
                                  color: palette.primary,
                                ),
                            ],
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

class _FormCell extends StatelessWidget {
  const _FormCell({
    required this.label,
    required this.glyph,
  });

  final String label;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    return Column(
      children: [
        JawiText(glyph, fontSize: 26, color: palette.ink),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.inkMuted,
              ),
        ),
      ],
    );
  }
}
