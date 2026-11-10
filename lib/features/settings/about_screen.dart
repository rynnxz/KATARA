import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  String _selectedDialectFilter = 'semua';
  bool _showAllReferences = false;

  static const List<DialectReferenceModel> _fallbackReferences = [
    DialectReferenceModel(
      id: 'SRC-MD-0001',
      courseId: 'ms-deli',
      dialectId: 'melayu_deli',
      title: 'Kamus Bahasa Melayu Deli - Indonesia (Balai Bahasa Sumatera Utara)',
      author: 'Tim Peneliti Balai Bahasa Provinsi Sumatera Utara',
      publicationYear: 2018,
      publisher: 'Balai Bahasa Sumatera Utara, Kemendikbud',
      url: 'https://balaibahasasumut.kemdikbud.go.id',
      sourceType: 'dictionary',
      reliability: 'high',
      accessedAt: '2026-11-10',
    ),
    DialectReferenceModel(
      id: 'SRC-LK-0001',
      courseId: 'ms-langkat',
      dialectId: 'melayu_langkat',
      title: 'Struktur Bahasa Melayu Langkat (Pusat Pembinaan dan Pengembangan Bahasa)',
      author: 'Siti Salamah Arifin, dkk.',
      publicationYear: 1985,
      publisher: 'Departemen Pendidikan dan Kebudayaan RI',
      url: 'https://repositori.kemdikbud.go.id',
      sourceType: 'academic_monograph',
      reliability: 'high',
      accessedAt: '2026-11-10',
    ),
    DialectReferenceModel(
      id: 'SRC-LK-0002',
      courseId: 'ms-langkat',
      dialectId: 'melayu_langkat',
      title: 'Kamus Dwibahasa Melayu Langkat - Indonesia',
      author: 'Balai Bahasa Provinsi Sumatera Utara',
      publicationYear: 2019,
      publisher: 'Kemendikbudristek RI',
      url: 'https://balaibahasasumut.kemdikbud.go.id',
      sourceType: 'dictionary',
      reliability: 'high',
      accessedAt: '2026-11-10',
    ),
    DialectReferenceModel(
      id: 'SRC-PLG-0001',
      courseId: 'ms-palembang',
      dialectId: 'melayu_palembang',
      title: 'Kamus Bahasa Palembang - Indonesia (Balai Bahasa Sumatera Selatan)',
      author: 'Tim Penyusun Balai Bahasa Sumatera Selatan',
      publicationYear: 2017,
      publisher: 'Balai Bahasa Provinsi Sumatera Selatan',
      url: 'https://balaibahasasumsel.kemdikbud.go.id',
      sourceType: 'dictionary',
      reliability: 'high',
      accessedAt: '2026-11-10',
    ),
    DialectReferenceModel(
      id: 'SRC-PLG-0002',
      courseId: 'ms-palembang',
      dialectId: 'melayu_palembang',
      title: 'Morfologi dan Sintaksis Bahasa Melayu Palembang (Bebaso & Sari-sari)',
      author: 'Zainal Abidin Gaffar, dkk.',
      publicationYear: 1986,
      publisher: 'Pusat Pembinaan dan Pengembangan Bahasa',
      url: 'https://repositori.kemdikbud.go.id',
      sourceType: 'academic_monograph',
      reliability: 'high',
      accessedAt: '2026-11-10',
    ),
  ];

  Future<Map<String, dynamic>> _loadCredits() async {
    try {
      final raw = await rootBundle.loadString('assets/content/credits.json');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Future<void> _openReferenceUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tautan rujukan: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final refsAsync = ref.watch(
      dialectReferencesProvider(
        _selectedDialectFilter == 'semua' ? null : _selectedDialectFilter,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang, Riset & Referensi'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadCredits(),
          builder: (context, snapshot) {
            final credits = snapshot.data ?? const {};
            final dbRefs = refsAsync.value ?? const [];
            final effectiveRefs = <DialectReferenceModel>[
              ...dbRefs,
              for (final fb in _fallbackReferences)
                if (!dbRefs.any((r) => r.id == fb.id) &&
                    (_selectedDialectFilter == 'semua' ||
                        fb.courseId == _selectedDialectFilter))
                  fb,
            ];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. TENTANG KATARA
                Text(
                  '1. Tentang KATARA',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                KCard(
                  selected: true,
                  child: Row(
                    children: [
                      const MascotView(state: MascotState.happy, size: 68),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KATARA v1.1.0 Multi-Dialek',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Platform pembelajaran bahasa dan budaya Melayu Nusantara berbasis riset linguistik, bekerja 100% luring (offline-first) dengan arsitektur modul unduhan mandiri serta sinkronisasi cloud opsional.',
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

                const SizedBox(height: 22),

                // 2. SUMBER DATA BAHASA & REFERENSI
                Text(
                  '2. Sumber Data Bahasa & Referensi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tab in const [
                        ('semua', 'Semua Dialek'),
                        ('ms-deli', 'Melayu Deli'),
                        ('ms-langkat', 'Melayu Langkat'),
                        ('ms-palembang', 'Melayu Palembang'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: KChip(
                            label: tab.$2,
                            selected: _selectedDialectFilter == tab.$1,
                            onTap: () => setState(
                                () => _selectedDialectFilter = tab.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...(_showAllReferences
                        ? effectiveRefs
                        : effectiveRefs.take(2))
                    .map((refItem) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: KCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              DialectIdentityBadge(courseId: refItem.courseId),
                              const SizedBox(width: 8),
                              KChip(label: refItem.id),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            refItem.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${refItem.author} (${refItem.publicationYear ?? 2020}) • ${refItem.publisher ?? 'Balai Bahasa'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: palette.inkMuted),
                          ),
                          if (refItem.url != null &&
                              refItem.url!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: KChip(
                                label: 'Buka Tautan Rujukan',
                                icon: Icons.open_in_new_rounded,
                                onTap: () => _openReferenceUrl(
                                    context, refItem.url!),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                if (effectiveRefs.length > 2)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: KChip(
                      label: _showAllReferences
                          ? 'Ringkas Daftar Rujukan'
                          : 'Tampilkan Semua (${effectiveRefs.length} Rujukan Akademik)',
                      icon: _showAllReferences
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      onTap: () => setState(
                          () => _showAllReferences = !_showAllReferences),
                    ),
                  ),

                const SizedBox(height: 22),

                // 3. METODOLOGI RISET LINGUISTIK
                Text(
                  '3. Metodologi Riset Linguistik',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kurasi Korpus & Pelacakan Provenans',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Setiap entri kosakata pada Melayu Deli (364 kata), Melayu Langkat (308 kata), dan Melayu Palembang (308 kata) melalui tahapan: (1) ekstraksi leksikon dari monograf Balai Bahasa dan kamus dwibahasa, (2) pencatatan transkripsi fonetik suku kata, (3) pemetaan tingkat tutur (halus/Bebaso, harian/Sari-sari, akrab), serta (4) penautan kode sumber (SRC-MD, SRC-LK, SRC-PLG).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.ink,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 4. ATRIBUSI & KONTRIBUTOR
                Text(
                  '4. Atribusi & Kontributor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credits['validation_notice'] as String? ??
                            'Setiap entri dilengkapi lencana status validasi agar pengguna mengetahui tingkat verifikasi akademik dan komunitas penutur.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          ValidationStatusBadge(status: 'draft'),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Draf: dihimpun dari literatur primer dan korpus kerja.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          ValidationStatusBadge(status: 'speaker_checked'),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Dicek Penutur: pemakaian harian dan lafal dikonfirmasi penutur asli.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          ValidationStatusBadge(status: 'expert_verified'),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Terverifikasi Ahli: ditinjau akademisi bahasa dan lembaga adat.',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 5. KETERBATASAN DATA & CATATAN DIALEK
                Text(
                  '5. Keterbatasan Data & Catatan Dialek',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Variasi Sub-Daerah & Ortografi Lisan',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bahasa daerah hidup secara lisan sehingga memiliki variasi antar-kecamatan (misalnya Medan Labuhan vs Deli Tua di Deli, Tanjung Pura vs Stabat di Langkat, serta Seberang Ulu vs Seberang Ilir di Palembang). Ejaan Latin yang ditampilkan menggunakan konvensi fonemik ramah pelajar dan mencantumkan varian ejaan alternatif pada detail kamus.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                              height: 1.5,
                            ),
                      ),
                    ],
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
