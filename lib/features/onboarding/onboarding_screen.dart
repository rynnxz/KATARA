import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_progress_bar.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0; // 0..2: slides, 3: tujuan, 4: target harian, 5: nama panggilan
  String _selectedGoal = 'Keluarga & akar budaya';
  int _selectedDailyMinutes = 10;
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;

  static const List<({String title, String subtitle, MascotState mascot})>
  _slides = [
    (
      title: 'Kenali Bahasa Melayu Serumpun',
      subtitle: 'Belajar sapaan, kosakata harian, hingga pantun Melayu Deli langkah demi langkah bersama Si Rebung.',
      mascot: MascotState.happy,
    ),
    (
      title: '100% Bisa Tanpa Internet',
      subtitle: 'Seluruh pelajaran, kamus, aksara Jawi, dan catatan budaya tersimpan langsung di ponselmu.',
      mascot: MascotState.idle,
    ),
    (
      title: 'Jujur pada Sumber & Penutur',
      subtitle: 'Setiap kosakata dan artikel budaya ditandai status validasinya agar kamu belajar dari rujukan yang jelas.',
      mascot: MascotState.cheer,
    ),
  ];

  static const List<({String title, String desc, IconData icon})> _goals = [
    (
      title: 'Keluarga & akar budaya',
      desc: 'Mengobrol akrab dengan keluarga atau kerabat di kampung halaman.',
      icon: Icons.people_alt_rounded,
    ),
    (
      title: 'Jalan-jalan & merantau',
      desc: 'Paham percakapan di pekan, kedai kopi, dan tempat bersejarah.',
      icon: Icons.explore_rounded,
    ),
    (
      title: 'Sastra, pantun & Jawi',
      desc: 'Membaca aksara Jawi dan mengenal kekayaan pantun Melayu.',
      icon: Icons.auto_stories_rounded,
    ),
    (
      title: 'Sekadar ingin tahu',
      desc:
          'Belajar santai 5 menit sehari untuk menambah wawasan bahasa daerah.',
      icon: Icons.lightbulb_rounded,
    ),
  ];

  static const List<({int minutes, String label, String desc})>
  _dailyTargets = [
    (minutes: 5, label: '5 menit / hari', desc: 'Santai • 1 pelajaran singkat'),
    (minutes: 10, label: '10 menit / hari', desc: 'Rutin • 2 pelajaran sehari'),
    (
      minutes: 20,
      label: '20 menit / hari',
      desc: 'Tekun • 3–4 pelajaran sehari',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    setState(() => _saving = true);
    try {
      final rawName = _nameController.text.trim();
      final displayName = rawName.isEmpty ? 'Pelajar Melayu' : rawName;
      await ref
          .read(progressRepositoryProvider)
          .updateProfile(
            displayName: displayName,
            learningGoal: _selectedGoal,
            dailyGoalMinutes: _selectedDailyMinutes,
            onboardingCompleted: true,
          );
      if (!mounted) return;
      context.go('/region');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _nextStep() {
    if (_step < 5) {
      setState(() => _step++);
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final progress = (_step + 1) / 6.0;

    return Scaffold(
      body: PatternBackground(
        opacity: 0.05,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        tooltip: 'Kembali',
                        onPressed: _prevStep,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: KProgressBar(
                        value: progress,
                        height: 12,
                        semanticLabel: 'Progres pengenalan',
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _saving ? null : _finishOnboarding,
                      child: Text(
                        'Lewati',
                        style: TextStyle(
                          color: palette.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStepBody(context, palette),
                  ),
                ),
                const SizedBox(height: 16),
                KButton(
                  label: _step < 5 ? 'Lanjut' : 'Pilih Daerah Belajar',
                  icon: _step < 5
                      ? Icons.arrow_forward_rounded
                      : Icons.map_rounded,
                  isLoading: _saving,
                  onPressed: _nextStep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(BuildContext context, KataraPalette palette) {
    if (_step < 3) {
      final slide = _slides[_step];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            MascotView(state: slide.mascot, size: 136),
            const SizedBox(height: 28),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 14),
            Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: palette.inkMuted, height: 1.5),
            ),
          ],
        ),
      );
    }

    if (_step == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apa tujuan utamamu belajar Bahasa Melayu?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Pilihan ini membantu Si Rebung menyiapkan sapaan penyemangatmu.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 20),
          ..._goals.map((g) {
            final isSelected = _selectedGoal == g.title;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KCard(
                selected: isSelected,
                onTap: () => setState(() => _selectedGoal = g.title),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.primary
                            : palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        g.icon,
                        color: isSelected ? palette.onPrimary : palette.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            g.desc,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }

    if (_step == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Berapa target belajarmu setiap hari?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Kamu bisa mengubah target harian kapan saja di menu Pengaturan.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 20),
          ..._dailyTargets.map((t) {
            final isSelected = _selectedDailyMinutes == t.minutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KCard(
                selected: isSelected,
                onTap: () => setState(() => _selectedDailyMinutes = t.minutes),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      color: isSelected ? palette.primary : palette.inkMuted,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.desc,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: MascotView(state: MascotState.happy, size: 100)),
        const SizedBox(height: 20),
        Text(
          'Siapa nama panggilanmu?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Opsional, tanpa perlu membuat akun. Progresmu langsung tersimpan di perangkat ini.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: palette.inkMuted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nama panggilan',
            hintText: 'Mis. Budi / Siti (kosongkan untuk "Pelajar Melayu")',
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.outline),
            ),
          ),
        ),
      ],
    );
  }
}
