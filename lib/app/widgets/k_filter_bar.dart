import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_chip.dart';

/// Model satu opsi kategori pada [KFilterBar].
class KFilterCategory {
  const KFilterCategory({required this.id, required this.label, this.count});

  final String id;
  final String label;
  final int? count;
}

/// Komponen bar filter kategori bersama yang bebas pemotongan horizontal (`Wrap`),
/// mendukung pemilihan satu atau multi-kategori, menampilkan jumlah item per kategori,
/// serta menyediakan ringkasan jumlah hasil dan tombol atur ulang filter (B4).
class KFilterBar extends StatefulWidget {
  const KFilterBar({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.allCategoryId = 'semua',
    this.totalCount,
    this.filteredCount,
    this.hasActiveSearch = false,
    this.onResetAll,
    this.collapsedCategoryLimit = 6,
    this.itemUnitLabel = 'kosakata',
  });

  final List<KFilterCategory> categories;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final String allCategoryId;
  final int? totalCount;
  final int? filteredCount;
  final bool hasActiveSearch;
  final VoidCallback? onResetAll;
  final int collapsedCategoryLimit;
  final String itemUnitLabel;

  @override
  State<KFilterBar> createState() => _KFilterBarState();
}

class _KFilterBarState extends State<KFilterBar> {
  bool _expanded = false;

  bool get _isAllSelected =>
      widget.selectedIds.isEmpty ||
      (widget.selectedIds.length == 1 &&
          widget.selectedIds.contains(widget.allCategoryId));

  void _handleTapCategory(String id) {
    if (id == widget.allCategoryId) {
      widget.onSelectionChanged(const <String>{});
      return;
    }

    final next = Set<String>.from(widget.selectedIds)
      ..remove(widget.allCategoryId);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onSelectionChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final total = widget.totalCount;
    final filtered = widget.filteredCount;
    final hasFilter = !_isAllSelected || widget.hasActiveSearch;

    // Tentukan kategori yang ditampilkan saat mode ringkas vs diperluas
    final allCats = widget.categories;
    final bool canCollapse = allCats.length > widget.collapsedCategoryLimit;
    final List<KFilterCategory> visibleCats;
    int hiddenCount = 0;

    if (!canCollapse || _expanded) {
      visibleCats = allCats;
    } else {
      final primarySlice = allCats.take(widget.collapsedCategoryLimit).toList();
      final selectedExtras = allCats
          .skip(widget.collapsedCategoryLimit)
          .where((c) => widget.selectedIds.contains(c.id))
          .toList();
      visibleCats = [...primarySlice, ...selectedExtras];
      hiddenCount = allCats.length - visibleCats.length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final cat in visibleCats)
                Builder(
                  builder: (context) {
                    final isAll = cat.id == widget.allCategoryId;
                    final isSelected = isAll
                        ? _isAllSelected
                        : widget.selectedIds.contains(cat.id);
                    final displayLabel = cat.count != null
                        ? '${cat.label} (${cat.count})'
                        : cat.label;
                    final semanticText = cat.count != null
                        ? 'Filter kategori ${cat.label}, ${cat.count} ${widget.itemUnitLabel}'
                        : 'Filter kategori ${cat.label}';

                    return KChip(
                      label: displayLabel,
                      selected: isSelected,
                      semanticLabel: semanticText,
                      onTap: () => _handleTapCategory(cat.id),
                    );
                  },
                ),
              if (canCollapse && !_expanded && hiddenCount > 0)
                KChip(
                  label: 'Lainnya (+$hiddenCount)',
                  icon: Icons.expand_more_rounded,
                  semanticLabel: 'Tampilkan $hiddenCount kategori lainnya',
                  onTap: () => setState(() => _expanded = true),
                )
              else if (canCollapse && _expanded)
                KChip(
                  label: 'Ringkas',
                  icon: Icons.expand_less_rounded,
                  semanticLabel: 'Ringkas daftar kategori',
                  onTap: () => setState(() => _expanded = false),
                ),
            ],
          ),
          if (total != null && filtered != null) ...[
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Menampilkan $filtered dari $total ${widget.itemUnitLabel}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hasFilter)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(48, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed:
                        widget.onResetAll ??
                        () => widget.onSelectionChanged(const <String>{}),
                    icon: Icon(
                      Icons.restart_alt_rounded,
                      size: 16,
                      color: palette.primary,
                    ),
                    label: Text(
                      'Atur ulang filter',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
