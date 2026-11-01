import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/app/widgets/jawi_text.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/k_header_stats.dart';
import 'package:katara/app/widgets/k_progress_bar.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/path_node.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/app/widgets/result_burst.dart';

class DevGalleryScreen extends StatefulWidget {
  const DevGalleryScreen({super.key});

  @override
  State<DevGalleryScreen> createState() => _DevGalleryScreenState();
}

class _DevGalleryScreenState extends State<DevGalleryScreen> {
  bool _previewDark = false;

  @override
  Widget build(BuildContext context) {
    final activeTheme = _previewDark ? KataraTheme.dark() : KataraTheme.light();

    return Theme(
      data: activeTheme,
      child: Builder(
        builder: (context) {
          final p = KataraPalette.of(context);
          return Scaffold(
            backgroundColor: p.bg,
            appBar: AppBar(
              title: const Text('Galeri Komponen KATARA'),
              actions: [
                TextButton.icon(
                  onPressed: () => setState(() => _previewDark = !_previewDark),
                  icon: Icon(
                    _previewDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  label: Text(_previewDark ? 'Tema Terang' : 'Tema Gelap'),
                ),
              ],
            ),
            body: PatternBackground(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const KHeaderStats(
                    streak: 5,
                    coins: 120,
                    hearts: 5,
                    xp: 240,
                    regionLabel: 'Melayu Deli',
                  ),
                  const SizedBox(height: 16),
                  KButton(
                    label: 'Uji Sesi Pelajaran Nyata (Unit 1 Pelajaran 1)',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.push('/lesson/ms-deli:l:0001'),
                  ),
                  const SizedBox(height: 20),
                  KCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verifikasi Aksara Jawi (Bagian 10.3)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const JawiText('ڠ ݢ ڤ ڽ چ ۏ'),
                        const SizedBox(height: 6),
                        Text(
                          'Huruf Jawi tambahan Melayu: nga (ڠ), ga (ݢ), pa (ڤ), nya (ڽ), ca (چ), va (ۏ).',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  KCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maskot Si Rebung (4 State)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            MascotView(state: MascotState.idle, size: 76),
                            MascotView(state: MascotState.happy, size: 76),
                            MascotView(state: MascotState.sad, size: 76),
                            MascotView(state: MascotState.cheer, size: 76),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  KCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tombol 3D (KButton) & Chip Validasi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            KButton(
                              label: 'Primer',
                              onPressed: () {},
                            ),
                            KButton(
                              label: 'Sekunder',
                              variant: KButtonVariant.secondary,
                              onPressed: () {},
                            ),
                            KButton(
                              label: 'Garis Tepi',
                              variant: KButtonVariant.outline,
                              onPressed: () {},
                            ),
                            const KButton(
                              label: 'Nonaktif',
                              onPressed: null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ValidationStatusBadge(status: 'draft'),
                            ValidationStatusBadge(status: 'speaker_checked'),
                            ValidationStatusBadge(status: 'expert_verified'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  KCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Node Peta Belajar (PathNode) & Progres',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        const KProgressBar(value: 0.65),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 20,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            PathNode(
                              title: 'Selesai',
                              status: PathNodeStatus.completed,
                              stars: 3,
                              onTap: () {},
                            ),
                            PathNode(
                              title: 'Aktif',
                              status: PathNodeStatus.active,
                              onTap: () {},
                            ),
                            const PathNode(
                              title: 'Terkunci',
                              status: PathNodeStatus.locked,
                            ),
                            PathNode(
                              title: 'Boss Unit',
                              status: PathNodeStatus.boss,
                              stars: 2,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const KCard(
                    child: ResultBurst(
                      xpEarned: 15,
                      stars: 3,
                      accuracyPercent: 100,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
