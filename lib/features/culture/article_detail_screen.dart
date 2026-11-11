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
import 'package:katara/app/widgets/report_issue_dialog.dart';
import 'package:katara/data/content/content_models.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  const ArticleDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  bool _claiming = false;
  bool _claimed = false;

  Future<void> _unlockCardAndQuest(ArticleModel article) async {
    setState(() => _claiming = true);
    try {
      await ref
          .read(progressRepositoryProvider)
          .unlockArticleAndCard(
            courseId: article.courseId,
            articleId: article.id,
            cardId: article.cardId,
          );
      await ref.read(sfxServiceProvider).playCorrect();
      if (!mounted) return;
      setState(() => _claimed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Artikel ditandai selesai dibaca & kartu koleksi berhasil dibuka!',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _claiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    return FutureBuilder<ArticleModel?>(
      future: ref.read(contentRepositoryProvider).getArticle(widget.articleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Artikel Budaya')),
            body: Center(
              child: CircularProgressIndicator(color: palette.primary),
            ),
          );
        }

        final article = snapshot.data;
        if (article == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Artikel Budaya')),
            body: const Center(child: Text('Artikel tidak ditemukan.')),
          );
        }

        final hasBody =
            article.bodyMarkdown != null &&
            article.bodyMarkdown!.trim().isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Wawasan Budaya'),
            actions: [
              IconButton(
                tooltip: 'Laporkan kesalahan',
                onPressed: () => showReportIssueSheet(
                  context,
                  ref,
                  courseId: article.courseId,
                  itemId: article.id,
                  itemType: 'article',
                  itemTitle: article.title,
                ),
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ),
          body: PatternBackground(
            opacity: 0.05,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    ValidationStatusBadge(status: article.validationStatus),
                    const SizedBox(width: 8),
                    KChip(label: 'Status: ${article.status}'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                if (hasBody)
                  KCard(
                    child: Text(
                      article.bodyMarkdown!,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(height: 1.6),
                    ),
                  )
                else
                  KCard(
                    backgroundColor: palette.surfaceAlt,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const MascotView(state: MascotState.idle, size: 56),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Naskah Lengkap Sedang Disusun',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sesuai prinsip keaslian konten KATARA, artikel budaya tidak dikarang otomatis. Naskah lengkap untuk topik ini sedang disusun dan diverifikasi bersama rujukan sejarah serta narasumber budaya Melayu Deli.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: palette.inkMuted, height: 1.5),
                        ),
                        if (article.verificationNotes != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.outline),
                            ),
                            child: Text(
                              'Poin verifikasi sumber: ${article.verificationNotes}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                if (article.sources.isNotEmpty) ...[
                  Text(
                    'Sumber & Sitasi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...article.sources.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $s',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.inkMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                KButton(
                  label: _claimed
                      ? 'Lihat Kartu Koleksi'
                      : 'Tandai Dibaca & Buka Kartu Koleksi',
                  icon: _claimed
                      ? Icons.collections_bookmark_rounded
                      : Icons.lock_open_rounded,
                  isLoading: _claiming,
                  onPressed: _claimed
                      ? () => context.push('/collection')
                      : () => _unlockCardAndQuest(article),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
