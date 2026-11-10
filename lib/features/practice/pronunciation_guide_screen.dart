import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';

class PronunciationGuideScreen extends ConsumerStatefulWidget {
  const PronunciationGuideScreen({super.key});

  @override
  ConsumerState<PronunciationGuideScreen> createState() =>
      _PronunciationGuideScreenState();
}

class _PronunciationGuideScreenState
    extends ConsumerState<PronunciationGuideScreen> {
  String _selectedDialect = 'ms-deli';

  static const _phonologyRules = <String, List<(String, String, String)>>{
    'ms-deli': [
      (
        'Pelemahan Vokal Akhir [-a] menjadi [-e]',
        'Vokal /a/ pada suku kata akhir terbuka bergeser menjadi vokal tengah [ə] (pepet) atau [e] (taling).',
        'apa -> ape [a.pə] • mana -> mane [ma.nə] • kita -> kite [ki.tə]',
      ),
      (
        'Hentian Glotal [ʔ] pada Akhir Kata [-k]',
        'Konsonan /k/ di akhir kata tidak diucapkan meletup velar, melainkan menjadi hentian glotal halus [ʔ].',
        'tidak -> tak [taʔ] • kakak -> kakak [ka.kaʔ] • anak -> anak [a.naʔ]',
      ),
      (
        'Monoftongisasi Difton [-ai] dan [-au]',
        'Dalam tuturan cepat di Medan dan Deli Serdang, diftong /-ai/ kerap bergeser menjadi [-e] dan /-au/ menjadi [-o].',
        'sampai -> sampe [sam.pe] • kedai -> kede [kə.de] • kalau -> kalo [ka.lo]',
      ),
    ],
    'ms-langkat': [
      (
        'Pelemahan Vokal Akhir [-a] Pesisir Langkat',
        'Selaras dengan Melayu Pesisir Timur Sumatera, vokal akhir /-a/ direalisasikan sebagai pepet [ə] dengan ritme mendayu khas Tanjung Pura.',
        'apa -> ape [a.pə] • siapa -> siape [si.a.pə] • lama -> lame [la.mə]',
      ),
      (
        'Partikel Penegas dan Sapaan Kekerabatan',
        'Intonasi kalimat tanya dan ajakan sering diperhalus dengan partikel "lah", "pun", dan sapaan adat "Wak", "Umak", atau "Atok".',
        'Singgahlah ke rumah Wak [siŋ.gah.lah kə ru.mah waʔ]',
      ),
      (
        'Retensi Konsonan Nasal dan Glotal Akhir',
        'Akhiran /-ng/ [ŋ] dan /-k/ [ʔ] diucapkan jelas tanpa penghilangan suku kata awal.',
        'kampung -> kampong [kam.poŋ] • petang -> petang [pə.taŋ]',
      ),
    ],
    'ms-palembang': [
      (
        'Pelemahan Vokal Akhir [-a] menjadi [-o] (Ciri Khas Musi)',
        'Berbeda dari Deli dan Langkat, Melayu Palembang mengubah vokal akhir /-a/ terbuka menjadi vokal bulat [-o] [ɔ/o].',
        'apa -> apo [a.po] • mana -> mano [ma.no] • kita -> kito [ki.to]',
      ),
      (
        'Dua Tingkat Tutur: Sari-sari vs Bebaso (Alus)',
        'Bahasa Palembang memiliki ragam harian (Sari-sari) dan ragam kehormatan kepada orang tua/tokoh adat (Bebaso).',
        'saya: aku (Sari-sari) / kulo (Alus) • makan: makan / dahar • tidur: tedok / sare',
      ),
      (
        'Klitika Penegas "nian", "bae", dan "galo"',
        'Penekanan makna kualitas menggunakan "nian" (sangat), pembatas "bae" (saja), dan kolektif "galo" (semua).',
        'lemak nian [lə.maʔ ni.an] • kito galo [ki.to ga.lo]',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final rules = _phonologyRules[_selectedDialect] ?? _phonologyRules['ms-deli']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Lafal & Fonologi'),
      ),
      body: PatternBackground(
        opacity: 0.04,
        courseId: _selectedDialect,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final d in const [
                  ('ms-deli', 'Melayu Deli'),
                  ('ms-langkat', 'Melayu Langkat'),
                  ('ms-palembang', 'Melayu Palembang'),
                ])
                  KChip(
                    label: d.$2,
                    selected: _selectedDialect == d.$1,
                    onTap: () => setState(() => _selectedDialect = d.$1),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Kaidah Fonologi Utama',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...rules.map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.record_voice_over_rounded,
                              color: palette.primary, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.$1,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.$2,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.outline),
                        ),
                        child: Text(
                          'Contoh: ${r.$3}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: palette.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Contoh Transkripsi Fonetik Kosakata',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<WordModel>>(
              future: ref
                  .read(contentRepositoryProvider)
                  .getWords(_selectedDialect),
              builder: (context, snapshot) {
                final words = (snapshot.data ?? const [])
                    .where((w) =>
                        w.pronunciation != null &&
                        w.pronunciation!.trim().isNotEmpty)
                    .take(12)
                    .toList();

                if (words.isEmpty) {
                  return KCard(
                    child: Text(
                      'Unduh modul dialek ini di menu Pilih Daerah untuk melihat daftar lengkap transkripsi fonetik ratusan kosakata.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.inkMuted,
                          ),
                    ),
                  );
                }

                return Column(
                  children: words.map((w) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(
                                    w.indonesia,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: palette.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            KChip(
                              label: '[${w.pronunciation}]',
                              icon: Icons.graphic_eq_rounded,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
