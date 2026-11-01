import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<Map<String, dynamic>> _loadCredits() async {
    try {
      final raw = await rootBundle.loadString('assets/content/credits.json');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang & Validasi Konten'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadCredits(),
          builder: (context, snapshot) {
            final credits = snapshot.data ?? const {};
            final notice = credits['validation_notice'] as String? ??
                'Seluruh kosakata, frasa, dan artikel budaya pada rilis awal ini berstatus Draf dan sedang melalui proses verifikasi bersama penutur asli Melayu Deli serta ahli bahasa/budaya.';
            final speakers =
                (credits['speakers'] as List<dynamic>? ?? const [])
                    .map((e) => e.toString())
                    .toList();
            final experts = (credits['experts'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                              'KATARA v0.1.0 (MVP)',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aplikasi belajar bahasa & budaya Melayu Nusantara bergaya interaktif, gratis, dan 100% dapat digunakan tanpa internet.',
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
                const SizedBox(height: 20),
                Text(
                  'Transparansi Status Validasi Konten',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          ValidationStatusBadge(status: 'draft'),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Draf awal dari korpus kerja pengembang; belum diperiksa penutur.',
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
                              'Dicek Penutur: pemakaian harian & lafal sudah dikonfirmasi penutur asli.',
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
                              'Terverifikasi Ahli: ejaan Rumi/Jawi dan rujukan sejarah sudah ditinjau akademisi/lembaga adat.',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kredit Penutur & Pemerhati Budaya',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Narasumber Penutur',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        speakers.isEmpty
                            ? 'Daftar penutur mitra sedang didokumentasikan seiring berjalannya tahap validasi lapangan.'
                            : speakers.join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Peninjau Ahli & Rujukan',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        experts.isEmpty
                            ? 'Daftar peninjau ahli bahasa & sejarah akan dicantumkan setelah verifikasi tahap kedua selesai.'
                            : experts.join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kebijakan Privasi Ringkas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                KCard(
                  child: Text(
                    'Pada versi luring (Fase 0–6), seluruh data progres belajar, statistik XP, streak, dan laporan koreksi disimpan secara lokal di basis data SQLite perangkat Anda. Tidak ada data pribadi yang dikirim ke server pihak ketiga, tidak ada pelacak iklan, dan Anda dapat menghapus seluruh data kapan saja melalui menu Pengaturan.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                          height: 1.5,
                        ),
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
