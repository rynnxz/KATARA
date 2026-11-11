import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/services/auth_error_mapper.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isSigningIn = false;
  String? _authErrorMessage;

  Future<void> _navigateNextAfterAuthChoice() async {
    final stats = await ref.read(progressRepositoryProvider).getStats();
    if (!mounted) return;
    if (!stats.onboardingCompleted) {
      context.go('/onboarding');
    } else if (stats.activeCourseId == null || stats.activeCourseId!.isEmpty) {
      context.go('/region');
    } else {
      context.go('/home/learn');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _authErrorMessage = null;
    });

    try {
      final syncService = ref.read(firebaseSyncServiceProvider);
      await syncService.signInWithGoogle();
      await syncService.syncNow();
      await ref.read(appSettingsProvider.notifier).setAuthMode('google');
      ref.invalidate(cloudProfileProvider);
      if (!mounted) return;
      await _navigateNextAfterAuthChoice();
    } catch (e, st) {
      if (!mounted) return;
      final friendly = AuthErrorMapper.toUserMessage(e, st);
      setState(() {
        _isSigningIn = false;
        _authErrorMessage = friendly;
      });
    }
  }

  Future<void> _handleContinueAsGuest() async {
    await ref.read(appSettingsProvider.notifier).setAuthMode('guest');
    if (!mounted) return;
    await _navigateNextAfterAuthChoice();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    return Scaffold(
      body: PatternBackground(
        opacity: 0.06,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: MascotView(state: MascotState.happy, size: 76),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selamat Datang di KATARA',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Belajar bahasa dan budaya Melayu Nusantara secara bertahap bersama Si Rebung. Pilih cara menyimpan progres belajarmu di bawah ini.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.inkMuted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    if (_authErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.error),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: palette.onErrorContainer,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _authErrorMessage!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: palette.onErrorContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    KCard(
                      selected: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                color: palette.primary,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sinkronisasi Lintas Perangkat',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cadangkan XP, streak harian, dan penguasaan kosakata ke akun Google agar aman saat berganti ponsel.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.inkMuted),
                          ),
                          const SizedBox(height: 14),
                          KButton(
                            label: 'Masuk dengan Google',
                            icon: Icons.login_rounded,
                            isLoading: _isSigningIn,
                            onPressed: _isSigningIn
                                ? null
                                : _handleGoogleSignIn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    KCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.offline_pin_rounded,
                                color: palette.primary,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Mode Tamu (100% Luring)',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Semua pelajaran, kamus, dan budaya terbuka penuh tanpa akun di perangkat ini. Kamu bisa masuk Google kapan saja lewat halaman Profil.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.inkMuted),
                          ),
                          const SizedBox(height: 14),
                          KButton(
                            label: 'Lanjut sebagai Tamu',
                            variant: KButtonVariant.outline,
                            icon: Icons.person_outline_rounded,
                            onPressed: _isSigningIn
                                ? null
                                : _handleContinueAsGuest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
