import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/k_filter_bar.dart';
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
  Set<String> _selectedCategories = const <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _debouncedQuery = '';
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _debouncedQuery = value.trim().toLowerCase();
      });
    });
  }

  void _resetAllFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategories = const <String>{};
      _debouncedQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final rowsAsync = ref.watch(dialectComparisonProvider('semua'));

    return Scaffold(
      appBar: AppBar(title: const Text('Perbandingan Dialek Melayu')),
      body: PatternBackground(
        opacity: 0.04,
        child: rowsAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: palette.primary)),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Gagal memuat komparasi dialek: $err'),
            ),
          ),
          data: (allRows) {
            final countsByCategory = <String, int>{};
            for (final r in allRows) {
              countsByCategory[r.category] =
                  (countsByCategory[r.category] ?? 0) + 1;
            }

            final filterCategories = _categories.map((cat) {
              final count = cat.$1 == 'semua'
                  ? allRows.length
                  : (countsByCategory[cat.$1] ?? 0);
              return KFilterCategory(id: cat.$1, label: cat.$2, count: count);
            }).toList();

            final q = _debouncedQuery;
            final filtered = allRows.where((r) {
              final matchesCategory =
                  _selectedCategories.isEmpty ||
                  _selectedCategories.contains('semua') ||
                  _selectedCategories.contains(r.category);
              if (!matchesCategory) return false;
              if (q.isEmpty) return true;
              return r.indonesia.toLowerCase().contains(q) ||
                  r.deliTerm.toLowerCase().contains(q) ||
                  r.langkatTerm.toLowerCase().contains(q) ||
                  r.palembangTerm.toLowerCase().contains(q);
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: KCard(
                          backgroundColor: palette.surfaceAlt,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Komparasi Lintas Dialek Nusantara',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bandingkan pergeseran vokal akhir Melayu Deli dan Langkat (pelemahan [-a] menjadi [-e] pepet/taling) dengan Melayu Palembang (pergeseran [-a] menjadi [-o]).',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: palette.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Cari kata atau arti',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Hapus pencarian',
                                    onPressed: () {
                                      _debounceTimer?.cancel();
                                      _searchController.clear();
                                      setState(() => _debouncedQuery = '');
                                    },
                                    icon: const Icon(Icons.clear_rounded),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      KFilterBar(
                        categories: filterCategories,
                        selectedIds: _selectedCategories,
                        totalCount: allRows.length,
                        filteredCount: filtered.length,
                        hasActiveSearch: q.isNotEmpty,
                        itemUnitLabel: 'entri',
                        onSelectionChanged: (next) {
                          setState(() => _selectedCategories = next);
                        },
                        onResetAll: _resetAllFilters,
                      ),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: palette.inkMuted,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tidak ada entri perbandingan yang cocok dengan filter atau pencarianmu.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                            const SizedBox(height: 14),
                            KButton(
                              label: 'Atur Ulang Filter',
                              variant: KButtonVariant.outline,
                              icon: Icons.restart_alt_rounded,
                              onPressed: _resetAllFilters,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _ComparisonCard(row: filtered[index]);
                      },
                    ),
                  ),
              ],
            );
          },
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'Arti Indonesia: "${row.indonesia}"',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row.linguisticNote,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rujukan: Balai Bahasa Sumatera Utara & Balai Bahasa Sumatera Selatan',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.inkMuted,
                      fontWeight: FontWeight.w700,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
              Text(
                word,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: palette.ink),
              ),
            ],
          ),
          if (pronunciation.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Lafal: $pronunciation',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
