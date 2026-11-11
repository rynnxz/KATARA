import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/domain/entities/user_progress.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  Future<void> _buyItem(ShopItemConfig item) async {
    final ok = await ref.read(progressRepositoryProvider).buyShopItem(item);
    if (!mounted) return;
    setState(() {});
    if (ok) {
      await ref.read(sfxServiceProvider).playCorrect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil membeli ${item.name}!')),
      );
    } else {
      await ref.read(sfxServiceProvider).playWrong();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koin tidak cukup atau batas kepemilikan tercapai.'),
        ),
      );
    }
  }

  IconData _iconForItem(String id) {
    return switch (id) {
      'streak_freeze' => Icons.ac_unit_rounded,
      'heart_refill' => Icons.favorite_rounded,
      'outfit_teluk_belanga' => Icons.checkroom_rounded,
      'outfit_kebaya_labuh' => Icons.checkroom_rounded,
      'theme_istana_maimun' => Icons.palette_rounded,
      _ => Icons.shopping_bag_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kedai Koin Si Rebung'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: statsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: palette.primary),
          ),
          error: (err, _) => Center(child: Text('Gagal memuat toko: $err')),
          data: (stats) => FutureBuilder<(GameConfig, Map<String, int>)>(
            future: () async {
              final config =
                  await ref.read(contentRepositoryProvider).getGameConfig();
              final inv =
                  await ref.read(progressRepositoryProvider).getInventory();
              return (config, inv);
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: CircularProgressIndicator(color: palette.primary),
                );
              }

              final config = snapshot.data?.$1;
              final inv = snapshot.data?.$2 ?? const {};
              final items = config?.shopItems ?? const [];

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  KCard(
                    selected: true,
                    child: Row(
                      children: [
                        const MascotView(state: MascotState.happy, size: 60),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo Koinmu: ${stats.coins}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pelindung Streak aktif: ${stats.streakFreezes} • Nyawa: ${stats.hearts}/5',
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
                  ...items.map((item) {
                    final ownedQty = item.id == 'streak_freeze'
                        ? stats.streakFreezes
                        : (inv[item.id] ?? 0);
                    final canAfford = stats.coins >= item.priceCoins;
                    final maxReached = item.maxOwned != null &&
                        ownedQty >= item.maxOwned!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: KCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: palette.secondaryContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _iconForItem(item.id),
                                    color: palette.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: palette.inkMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                if (ownedQty > 0)
                                  KChip(label: 'Dimiliki: $ownedQty'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            KButton(
                              label: maxReached
                                  ? 'Batas Maksimal Tercapai'
                                  : 'Tukar ${item.priceCoins} Koin',
                              variant: canAfford && !maxReached
                                  ? KButtonVariant.primary
                                  : KButtonVariant.outline,
                              onPressed: canAfford && !maxReached
                                  ? () => _buyItem(item)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
