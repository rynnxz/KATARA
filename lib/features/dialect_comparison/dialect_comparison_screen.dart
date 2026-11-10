import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';

class DialectComparisonScreen extends ConsumerStatefulWidget {
  const DialectComparisonScreen({super.key});

  @override
  ConsumerState<DialectComparisonScreen> createState() =>
      _DialectComparisonScreenState();
}

class _DialectComparisonScreenState
    extends ConsumerState<DialectComparisonScreen> {
  String _selectedCategory = 'semua';
  final TextEditingController _searchController = TextEditingController();

  static const List<(String, String)> _categories = [
    ('semua', 'Semua'),
    ('sapaan', 'Sapaan'),
    ('tanya', 'Kata Tanya'),
    ('pronomina', 'Kata Ganti'),
    ('keluarga', 'Keluarga'),
    ('makanan', 'Kuliner'),
    ('sifat', 'Kata Sifat'),
    ('kerja', 'Kata Kerja'),
    ('tempat', 'Tempat'),
    ('waktu', 'Waktu'),
    ('angka', 'Angka'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final rowsAsync = ref.watch(dialectComparisonProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perbandingan Dialek Melayu'),
      ),
      body: PatternBackground(
        opacity: 0.04,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: KCard(
                backgroundColor: palette.surfaceAlt,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Komparasi Lintas Dialek Nusantara',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bandingkan pergeseran vokal akhir Melayu Deli dan Langkat (pelemahan [-a] menjadi [-e] pepet/taling) dengan Melayu Palembang (pergeseran [-a] menjadi [-o]).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari arti Indonesia, kata Deli, Langkat, atau Palembang...',
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
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: KChip(
                      label: cat.$2,
                      selected: selected,
                      onTap: () => setState(() => _selectedCategory = cat.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: rowsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: palette.primary),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gagal memuat komparasi dialek: $err'),
                  ),
                ),
                data: (rows) {
                  final q = _searchController.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? rows
                      : rows.where((r) {
                          return r.indonesia.toLowerCase().contains(q) ||
                              r.deliTerm.toLowerCase().contains(q) ||
                              r.langkatTerm.toLowerCase().contains(q) ||
                              r.palembangTerm.toLowerCase().contains(q);
                        }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Tidak ada entri perbandingan yang cocok dengan pencarianmu.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: palette.inkMuted,
                              ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _ComparisonCard(row: filtered[index]);
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

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.row});

  final DialectComparisonRowModel row;

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Arti Indonesia: "${row.indonesia}"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                KChip(label: row.category),
              ],
            ),
            const SizedBox(height: 12),
            _DialectVariantTile(
              courseId: 'ms-deli',
              dialectTitle: 'Melayu Deli',
              word: row.deliTerm,
              pronunciation: row.deliPronunciation,
            ),
            const SizedBox(height: 8),
            _DialectVariantTile(
              courseId: 'ms-langkat',
              dialectTitle: 'Melayu Langkat',
              word: row.langkatTerm,
              pronunciation: row.langkatPronunciation,
            ),
            const SizedBox(height: 8),
            _DialectVariantTile(
              courseId: 'ms-palembang',
              dialectTitle: 'Melayu Palembang',
              word: row.palembangTerm,
              pronunciation: row.palembangPronunciation,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: palette.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.linguisticNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.ink,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialectVariantTile extends StatelessWidget {
  const _DialectVariantTile({
    required this.courseId,
    required this.dialectTitle,
    required this.word,
    required this.pronunciation,
  });

  final String courseId;
  final String dialectTitle;
  final String word;
  final String pronunciation;

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final identity = DialectVisualIdentity.forCourse(courseId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeBg = isDark ? identity.badgeBgDark : identity.badgeBgLight;
    final badgeFg = isDark ? identity.badgeFgDark : identity.badgeFgLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outline, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dialectTitle,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: badgeFg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              word,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
            ),
          ),
          Text(
            pronunciation,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
