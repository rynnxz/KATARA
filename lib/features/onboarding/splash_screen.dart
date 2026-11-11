import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/domain/rules/gamification_rules.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        try {
          await ref
              .read(moduleDownloadServiceProvider)
              .cleanupStaleStagingDirectories();
        } catch (_) {}
      }

      final seeder = ref.read(contentSeederProvider);
      await seeder.seedIfNeeded();

      final progressRepo = ref.read(progressRepositoryProvider);
      final stats = await progressRepo.getStats();

      final settings = await ref.read(settingsServiceProvider).load();
      final notif = ref.read(notificationServiceProvider);
      await notif.initialize();

      if (settings.reminderEnabled) {
        final todayStr = GamificationRules.formatLocalDate(DateTime.now());
        await notif.rescheduleDailyReminder(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
          alreadyStudiedToday: stats.lastActiveDate == todayStr,
        );
      } else {
        await notif.cancelAll();
      }

      if (!mounted) return;

      if (!stats.onboardingCompleted) {
        context.go('/onboarding');
      } else if (stats.activeCourseId == null || stats.activeCourseId!.isEmpty) {
        context.go('/region');
      } else {
        context.go('/home/learn');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal menyiapkan basis data lokal: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    return Scaffold(
      body: PatternBackground(
        opacity: 0.08,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MascotView(state: MascotState.cheer, size: 120),
                  const SizedBox(height: 20),
                  Text(
                    'KATARA',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: palette.primary,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bahasa & Budaya Melayu Nusantara',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading) ...[
                    CircularProgressIndicator(color: palette.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Menyiapkan kamus & pelajaran luring...',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: palette.inkMuted,
                          ),
                    ),
                  ] else if (_errorMessage != null) ...[
                    Icon(Icons.error_outline_rounded,
                        color: palette.error, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.error,
                          ),
                    ),
                    const SizedBox(height: 16),
                    KButton(
                      label: 'Coba Lagi',
                      icon: Icons.refresh_rounded,
                      onPressed: _bootstrap,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
