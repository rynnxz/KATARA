import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);
    final courseId = statsAsync.value?.activeCourseId ?? 'ms-deli';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartu Koleksi Budaya'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: FutureBuilder<(List<CollectionCardModel>, Set<String>)>(
          future: () async {
            final cards = await ref
                .read(contentRepositoryProvider)
                .getCollectionCards(courseId);
            final unlocked = await ref
                .read(progressRepositoryProvider)
                .getUnlockedCards(courseId);
            return (cards, unlocked);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: palette.primary),
              );
            }

            final cards = snapshot.data?.$1 ?? const [];
            final unlockedIds = snapshot.data?.$2 ?? const {};

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final isUnlocked = unlockedIds.contains(card.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: KCard(
                    selected: isUnlocked,
                    backgroundColor: isUnlocked
                        ? palette.surface
                        : palette.surfaceAlt,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? palette.secondaryContainer
                                : palette.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.outline),
                          ),
                          child: Icon(
                            isUnlocked
                                ? Icons.auto_awesome_rounded
                                : Icons.lock_rounded,
                            color: isUnlocked
                                ? palette.onSecondaryContainer
                                : palette.inkMuted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      card.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: isUnlocked
                                                ? palette.ink
                                                : palette.inkMuted,
                                          ),
                                    ),
                                  ),
                                  KChip(
                                    label: card.category,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isUnlocked
                                    ? (card.fact ??
                                        'Fakta ringkas sedang disusun bersama narasumber budaya (draf).')
                                    : 'Terkunci • Baca artikel budaya atau selesaikan unit terkait untuk membuka kartu ini.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: palette.inkMuted),
                              ),
                              const SizedBox(height: 8),
                              ValidationStatusBadge(
                                status: card.validationStatus,
                              ),
                            ],
                          ),
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
    );
  }
}
