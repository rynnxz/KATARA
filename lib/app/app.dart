import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/router.dart';
import 'package:katara/app/theme/katara_theme.dart';

class KataraApp extends ConsumerWidget {
  const KataraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: 'KATARA',
      debugShowCheckedModeBanner: false,
      theme: KataraTheme.light(),
      darkTheme: KataraTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
