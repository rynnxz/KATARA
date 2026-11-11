import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';

class CultureScreen extends ConsumerWidget {
  const CultureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);
    final courseId = statsAsync.value?.activeCourseId ?? 'ms-deli';
    final activeCourseName =
        ref.watch(activeCourseProvider).value?.name ?? 'Melayu Deli';

    return Scaffold(
      appBar: AppBar(title: const Text('Ruang Budaya Melayu')),
      body: PatternBackground(
        opacity: 0.05,
        child: FutureBuilder<(List<ArticleModel>, List<CollectionCardModel>, Set<String>)>(
          future: () async {
            final contentRepo = ref.read(contentRepositoryProvider);
            final progressRepo = ref.read(progressRepositoryProvider);
            final articles = await contentRepo.getArticles(courseId);
            final cards = await contentRepo.getCollectionCards(courseId);
            final unlockedCards = await progressRepo.getUnlockedCards(courseId);
            return (articles, cards, unlockedCards);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: palette.primary),
              );
            }

            final articles = snapshot.data?.$1 ?? const [];
            final cards = snapshot.data?.$2 ?? const [];
            final unlockedCardIds = snapshot.data?.$3 ?? const {};

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                KCard(
                  selected: true,
                  child: Row(
                    children: [
                      const MascotView(state: MascotState.happy, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jejak Sejarah & Adat ${activeCourseName.replaceFirst('Melayu ', '')}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kenali bangunan bersejarah, busana adat, kuliner, dan sastra pantun sambil mengumpulkan kartu koleksi.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: KButton(
                        label:
                            'Kartu Koleksi (${unlockedCardIds.length}/${cards.length})',
                        icon: Icons.collections_bookmark_rounded,
                        onPressed: () => context.push('/collection'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KButton(
                        label: 'Aksara Jawi',
                        variant: KButtonVariant.secondary,
                        icon: Icons.auto_stories_rounded,
                        onPressed: () => context.push('/jawi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Artikel Budaya (${articles.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...articles.map((article) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KCard(
                      onTap: () => context.push('/article/${article.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ValidationStatusBadge(
                                status: article.validationStatus,
                              ),
                              const SizedBox(width: 8),
                              KChip(
                                label: article.bodyMarkdown == null
                                    ? 'Draf Kerangka'
                                    : 'Tersedia',
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: palette.inkMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            article.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (article.verificationNotes != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Catatan verifikasi: ${article.verificationNotes}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                          ],
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
