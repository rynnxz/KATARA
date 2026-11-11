import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/k_progress_bar.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/domain/rules/gamification_rules.dart';
import 'package:katara/services/auth_error_mapper.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);
    final activeCourseAsync = ref.watch(activeCourseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Statistik'),
        actions: [
          IconButton(
            tooltip: 'Tentang & Validasi Konten',
            onPressed: () => context.push('/about'),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: statsAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: palette.primary)),
          error: (_, _) => const Center(
            child: Text('Gagal memuat profil saat ini. Silakan muat ulang.'),
          ),
          data: (stats) {
            final title = GamificationRules.titleForLevel(stats.level);
            final displayLabel =
                (stats.displayName.trim().isEmpty ||
                    (stats.displayName == 'Perantau' && title == 'Perantau'))
                ? 'Pelajar Melayu'
                : stats.displayName;
            final levelProgress = GamificationRules.progressWithinCurrentLevel(
              stats.xpTotal,
            );
            final nextLevelReq = GamificationRules.xpRequiredForNextLevel(
              stats.level,
            );
            final activeCourseName =
                activeCourseAsync.value?.name ?? 'Melayu Deli';

            return FutureBuilder<(Map<String, int>, Set<String>, Set<String>)>(
              future: () async {
                final repo = ref.read(progressRepositoryProvider);
                final weekly = await repo.getWeeklyXpByDate(days: 7);
                final activeDates = await repo.getActiveDatesHistory();
                final badges = await repo.getUnlockedAchievements();
                return (weekly, activeDates, badges);
              }(),
              builder: (context, snapshot) {
                final weeklyXp = snapshot.data?.$1 ?? const {};
                final activeDates = snapshot.data?.$2 ?? const {};
                final unlockedBadges = snapshot.data?.$3 ?? const {};

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    KCard(
                      selected: true,
                      child: Column(
                        children: [
                          const MascotView(state: MascotState.cheer, size: 96),
                          const SizedBox(height: 12),
                          Text(
                            displayLabel,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: palette.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          KChip(
                            label: 'Level ${stats.level} • Gelar $title',
                            backgroundColor: palette.secondaryContainer,
                            textColor: palette.onSecondaryContainer,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Total XP: ${stats.xpTotal}',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: palette.onPrimaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  'Target naik level: +$nextLevelReq XP per tingkat',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: palette.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          KProgressBar(
                            value: levelProgress,
                            height: 10,
                            semanticLabel: 'Progres level ${stats.level}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _CloudSyncAccountCard(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: KCard(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  color: palette.streak,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${stats.streakCurrent} Hari',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Streak Saat Ini (Rekor: ${stats.streakBest})',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KCard(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  color: palette.secondary,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${unlockedBadges.length}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Lencana Terbuka',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    KCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalender Streak & XP 7 Hari Terakhir',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: weeklyXp.entries.map((entry) {
                              final dateStr = entry.key;
                              final xp = entry.value;
                              final isActive =
                                  activeDates.contains(dateStr) || xp > 0;
                              final dayLabel = dateStr.substring(8);

                              return Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? palette.streak
                                          : palette.surfaceAlt,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isActive
                                          ? Icons.local_fire_department_rounded
                                          : Icons.remove_rounded,
                                      color: isActive
                                          ? Colors.white
                                          : palette.inkMuted,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dayLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '+$xp',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: palette.inkMuted),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    KCard(
                      onTap: () => context.push('/region'),
                      child: Row(
                        children: [
                          Icon(Icons.map_rounded, color: palette.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daerah Aktif: $activeCourseName',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Ketuk untuk mengganti atau melihat daerah Melayu lainnya',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: palette.inkMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: KButton(
                            label: 'Pengaturan',
                            variant: KButtonVariant.outline,
                            icon: Icons.settings_rounded,
                            onPressed: () => context.push('/settings'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KButton(
                            label: 'Tentang & Kredit',
                            variant: KButtonVariant.outline,
                            icon: Icons.verified_user_outlined,
                            onPressed: () => context.push('/about'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CloudSyncAccountCard extends ConsumerStatefulWidget {
  const _CloudSyncAccountCard();

  @override
  ConsumerState<_CloudSyncAccountCard> createState() =>
      _CloudSyncAccountCardState();
}

class _CloudSyncAccountCardState extends ConsumerState<_CloudSyncAccountCard> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final profileAsync = ref.watch(cloudProfileProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (profile) {
        return KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    profile.isGuest
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    color: profile.isGuest ? palette.inkMuted : palette.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.isGuest
                              ? 'Sinkronisasi Cloud (Mode Tamu)'
                              : 'Terhubung: ${profile.email ?? profile.displayName}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.isGuest
                              ? 'Progres tersimpan aman di perangkat. Masuk dengan Google untuk mencadangkan lintas perangkat.'
                              : 'Progres XP, streak, dan penguasaan kosakata tersinkronisasi ke Firebase Cloud.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (profile.isGuest)
                    Expanded(
                      child: KButton(
                        label: 'Masuk dengan Google',
                        icon: Icons.login_rounded,
                        isLoading: _isBusy,
                        onPressed: _isBusy
                            ? null
                            : () async {
                                setState(() => _isBusy = true);
                                try {
                                  await ref
                                      .read(firebaseSyncServiceProvider)
                                      .signInWithGoogle();
                                  await ref
                                      .read(firebaseSyncServiceProvider)
                                      .syncNow();
                                  await ref
                                      .read(appSettingsProvider.notifier)
                                      .setAuthMode('google');
                                  ref.invalidate(cloudProfileProvider);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Berhasil masuk & menyinkronkan progres ke Cloud!',
                                      ),
                                    ),
                                  );
                                } catch (e, st) {
                                  if (!context.mounted) return;
                                  final friendlyMsg =
                                      AuthErrorMapper.toUserMessage(e, st);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(friendlyMsg)),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isBusy = false);
                                  }
                                }
                              },
                      ),
                    )
                  else ...[
                    Expanded(
                      child: KButton(
                        label: 'Sinkronkan Sekarang',
                        icon: Icons.sync_rounded,
                        isLoading: _isBusy,
                        onPressed: _isBusy
                            ? null
                            : () async {
                                setState(() => _isBusy = true);
                                try {
                                  final report = await ref
                                      .read(firebaseSyncServiceProvider)
                                      .syncNow();
                                  ref.invalidate(cloudProfileProvider);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Sinkronisasi selesai (${report.pushedItems} dikirim, ${report.pulledItems} diterima).',
                                      ),
                                    ),
                                  );
                                } catch (e, st) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AuthErrorMapper.toUserMessage(e, st),
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isBusy = false);
                                  }
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    KButton(
                      label: 'Keluar',
                      variant: KButtonVariant.outline,
                      onPressed: _isBusy
                          ? null
                          : () async {
                              setState(() => _isBusy = true);
                              try {
                                await ref
                                    .read(firebaseSyncServiceProvider)
                                    .signOutToGuest();
                                await ref
                                    .read(appSettingsProvider.notifier)
                                    .setAuthMode('guest');
                                ref.invalidate(cloudProfileProvider);
                              } finally {
                                if (mounted) {
                                  setState(() => _isBusy = false);
                                }
                              }
                            },
                    ),
                  ],
                ],
              ),
              if (!profile.isGuest) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Akun & Data Cloud?'),
                                content: const Text(
                                  'Seluruh data cadangan akunmu di server Cloud (profil, progres sinkronisasi, dan riwayat XP cloud) akan dihapus permanen sesuai hak privasi data. Progres belajar offline di perangkat ini tetap aman sebagai Mode Tamu.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: palette.error,
                                      foregroundColor: palette.onPrimary,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Hapus Permanen'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !context.mounted) return;
                            setState(() => _isBusy = true);
                            try {
                              await ref
                                  .read(firebaseSyncServiceProvider)
                                  .deleteAccountAndCloudData();
                              await ref
                                  .read(appSettingsProvider.notifier)
                                  .setAuthMode('guest');
                              ref.invalidate(cloudProfileProvider);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Akun & data Cloud berhasil dihapus. Beralih ke Mode Tamu.',
                                  ),
                                ),
                              );
                            } catch (e, st) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AuthErrorMapper.toUserMessage(e, st),
                                  ),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isBusy = false);
                              }
                            }
                          },
                    icon: Icon(
                      Icons.delete_forever_rounded,
                      size: 18,
                      color: palette.error,
                    ),
                    label: Text(
                      'Hapus Akun & Data Cloud',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
