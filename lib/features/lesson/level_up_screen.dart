import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';

class LevelUpScreen extends ConsumerWidget {
  const LevelUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final result = ref.watch(lastLessonResultProvider);

    final newLevel = result?.newLevel ?? 2;
    final newTitle = result?.newTitle ?? 'Perantau';
    final bonusCoins = result?.levelUpCoinsReward ?? (newLevel * 5);

    return Scaffold(
      body: PatternBackground(
        opacity: 0.08,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Center(
                  child: MascotView(state: MascotState.cheer, size: 136),
                ),
                const SizedBox(height: 24),
                Text(
                  'Naik ke Level $newLevel!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge
                      ?.copyWith(color: palette.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gelar Melayu: $newTitle',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: palette.inkMuted),
                ),
                const SizedBox(height: 24),
                KCard(
                  selected: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: palette.coin,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Hadiah Naik Level: +$bonusCoins Koin',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                KButton(
                  label: 'Lanjut ke Peta',
                  icon: Icons.map_rounded,
                  onPressed: () => context.go('/home/learn'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
