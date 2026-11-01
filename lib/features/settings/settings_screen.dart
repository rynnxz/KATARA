import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/domain/rules/gamification_rules.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    int currentHour,
    int currentMinute,
    String? lastActiveDate,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (picked == null) return;

    await ref.read(appSettingsProvider.notifier).updateReminder(
          enabled: true,
          hour: picked.hour,
          minute: picked.minute,
        );
    final notif = ref.read(notificationServiceProvider);
    await notif.requestPermissionWithContext();
    final todayStr = GamificationRules.formatLocalDate(DateTime.now());
    await notif.rescheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
      alreadyStudiedToday: lastActiveDate == todayStr,
    );
  }

  Future<void> _confirmResetData(BuildContext context, WidgetRef ref) async {
    final palette = context.kataraPalette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: const Text('Hapus Semua Progres Lokal?'),
        content: const Text(
          'Seluruh XP, streak, koin, lencana, dan penguasaan kata di perangkat ini akan diatur ulang ke kondisi awal. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Ya, Hapus Data',
              style: TextStyle(
                color: palette.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(progressRepositoryProvider).resetAllUserData();
    if (!context.mounted) return;
    context.go('/splash');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final statsAsync = ref.watch(userStatsStreamProvider);
    final stats = statsAsync.value;

    final reminderTimeLabel =
        '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: PatternBackground(
        opacity: 0.04,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Tampilan & Tema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            KCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Tema',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      KChip(
                        label: 'Terang',
                        icon: Icons.light_mode_rounded,
                        selected: settings.themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(appSettingsProvider.notifier)
                            .updateThemeMode(ThemeMode.light),
                      ),
                      KChip(
                        label: 'Gelap',
                        icon: Icons.dark_mode_rounded,
                        selected: settings.themeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(appSettingsProvider.notifier)
                            .updateThemeMode(ThemeMode.dark),
                      ),
                      KChip(
                        label: 'Sistem',
                        icon: Icons.brightness_auto_rounded,
                        selected: settings.themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(appSettingsProvider.notifier)
                            .updateThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tampilkan Aksara Jawi Pendamping'),
                    subtitle: const Text(
                      'Menampilkan tulisan Jawi di samping kata Latin bila tersedia',
                    ),
                    value: settings.showJawiScript,
                    onChanged: (val) => ref
                        .read(appSettingsProvider.notifier)
                        .toggleShowJawi(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belajar & Gamifikasi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            KCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Belajar Harian',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [5, 10, 20].map((mins) {
                      final isSelected =
                          (stats?.dailyGoalMinutes ?? 10) == mins;
                      return KChip(
                        label: '$mins menit/hari',
                        selected: isSelected,
                        onTap: () => ref
                            .read(progressRepositoryProvider)
                            .updateProfile(dailyGoalMinutes: mins),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mode Santai (Tanpa Kehilangan Nyawa)'),
                    subtitle: const Text(
                      'Nyawa otomatis nonaktif di Level 1. Aktifkan opsi ini bila ingin belajar tanpa batas nyawa di semua level.',
                    ),
                    value: stats?.casualMode ?? false,
                    onChanged: (val) => ref
                        .read(progressRepositoryProvider)
                        .updateProfile(casualMode: val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pengingat & Suara',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            KCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pengingat Streak Harian'),
                    subtitle: Text(
                      'Notifikasi lokal pukul $reminderTimeLabel (tanpa server)',
                    ),
                    value: settings.reminderEnabled,
                    onChanged: (val) async {
                      await ref
                          .read(appSettingsProvider.notifier)
                          .updateReminder(enabled: val);
                      final notif = ref.read(notificationServiceProvider);
                      if (val) {
                        await notif.requestPermissionWithContext();
                        final todayStr =
                            GamificationRules.formatLocalDate(DateTime.now());
                        await notif.rescheduleDailyReminder(
                          hour: settings.reminderHour,
                          minute: settings.reminderMinute,
                          alreadyStudiedToday:
                              stats?.lastActiveDate == todayStr,
                        );
                      } else {
                        await notif.cancelAll();
                      }
                    },
                  ),
                  if (settings.reminderEnabled)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: KChip(
                        label: 'Ubah Jam Pengingat ($reminderTimeLabel)',
                        icon: Icons.access_time_rounded,
                        onTap: () => _pickReminderTime(
                          context,
                          ref,
                          settings.reminderHour,
                          settings.reminderMinute,
                          stats?.lastActiveDate,
                        ),
                      ),
                    ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Efek Suara'),
                    value: settings.soundEnabled,
                    onChanged: (val) =>
                        ref.read(appSettingsProvider.notifier).toggleSound(val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Getaran Haptic Ringan'),
                    value: settings.hapticEnabled,
                    onChanged: (val) => ref
                        .read(appSettingsProvider.notifier)
                        .toggleHaptic(val),
                  ),
                  if (kDebugMode) ...[
                    const Divider(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mode Debug: Tampilkan Soal Perlu Verifikasi',
                      ),
                      subtitle: const Text(
                        'Menampilkan soal kuis bertanda needs_verification',
                      ),
                      value: settings.debugIncludeUnverified,
                      onChanged: (val) => ref
                          .read(appSettingsProvider.notifier)
                          .toggleDebugUnverified(val),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            KButton(
              label: 'Hapus Semua Data & Progres Lokal',
              variant: KButtonVariant.outline,
              icon: Icons.delete_forever_rounded,
              onPressed: () => _confirmResetData(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
