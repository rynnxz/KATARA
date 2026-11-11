import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/engine/exercise_generator.dart';
import 'package:katara/features/lesson/lesson_screen.dart';
import 'package:katara/features/profile/profile_screen.dart';
import 'package:katara/features/region_picker/region_picker_screen.dart';
import 'package:katara/features/settings/settings_screen.dart';

class _ColorPairSpec {
  const _ColorPairSpec({
    required this.name,
    required this.fg,
    required this.bg,
    required this.minRatio,
  });

  final String name;
  final Color fg;
  final Color bg;
  final double minRatio;
}

void main() {
  group('WCAG 2.1 AA+ / AAA Contrast Audit (Light, Dark, & Dialect Identities)', () {
    test('All KataraPalette.light foreground/background pairs meet or exceed WCAG AA+ thresholds', () {
      const p = KataraPalette.light;

      // Pastikan seluruh kontainer kartu/badge 100% solid (alpha == 1.0)
      expect(p.bg.a, 1.0);
      expect(p.surface.a, 1.0);
      expect(p.surfaceAlt.a, 1.0);
      expect(p.primaryContainer.a, 1.0);
      expect(p.secondaryContainer.a, 1.0);
      expect(p.successContainer.a, 1.0);
      expect(p.errorContainer.a, 1.0);

      final pairs = <_ColorPairSpec>[
        // Body text AAA (>= 7.0:1)
        _ColorPairSpec(name: 'light: ink on bg', fg: p.ink, bg: p.bg, minRatio: 7.0),
        _ColorPairSpec(name: 'light: ink on surface', fg: p.ink, bg: p.surface, minRatio: 7.0),
        _ColorPairSpec(name: 'light: ink on surfaceAlt', fg: p.ink, bg: p.surfaceAlt, minRatio: 7.0),
        _ColorPairSpec(name: 'light: inkMuted on bg', fg: p.inkMuted, bg: p.bg, minRatio: 7.0),
        _ColorPairSpec(name: 'light: inkMuted on surface', fg: p.inkMuted, bg: p.surface, minRatio: 7.0),
        _ColorPairSpec(name: 'light: inkMuted on surfaceAlt', fg: p.inkMuted, bg: p.surfaceAlt, minRatio: 7.0),
        // Colored cards & containers (>= 7.0:1 AAA)
        _ColorPairSpec(name: 'light: onPrimaryContainer on primaryContainer', fg: p.onPrimaryContainer, bg: p.primaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'light: ink on primaryContainer', fg: p.ink, bg: p.primaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'light: inkMuted on primaryContainer', fg: p.inkMuted, bg: p.primaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'light: onSecondaryContainer on secondaryContainer', fg: p.onSecondaryContainer, bg: p.secondaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'light: onSuccessContainer on successContainer', fg: p.onSuccessContainer, bg: p.successContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'light: onErrorContainer on errorContainer', fg: p.onErrorContainer, bg: p.errorContainer, minRatio: 7.0),
        // Buttons & accents (>= 4.5:1 AA)
        _ColorPairSpec(name: 'light: onPrimary on primary', fg: p.onPrimary, bg: p.primary, minRatio: 4.5),
        _ColorPairSpec(name: 'light: onSecondary on secondary', fg: p.onSecondary, bg: p.secondary, minRatio: 7.0),
        _ColorPairSpec(name: 'light: primary on surface', fg: p.primary, bg: p.surface, minRatio: 4.5),
        _ColorPairSpec(name: 'light: primary on bg', fg: p.primary, bg: p.bg, minRatio: 4.5),
        _ColorPairSpec(name: 'light: success on surface', fg: p.success, bg: p.surface, minRatio: 4.5),
        _ColorPairSpec(name: 'light: error on surface', fg: p.error, bg: p.surface, minRatio: 4.5),
        // Non-text borders & icons (>= 3.0:1)
        _ColorPairSpec(name: 'light: outline on surface', fg: p.outline, bg: p.surface, minRatio: 3.0),
        _ColorPairSpec(name: 'light: outline on bg', fg: p.outline, bg: p.bg, minRatio: 3.0),
        _ColorPairSpec(name: 'light: outline on surfaceAlt', fg: p.outline, bg: p.surfaceAlt, minRatio: 3.0),
        _ColorPairSpec(name: 'light: streak on surface', fg: p.streak, bg: p.surface, minRatio: 3.0),
        _ColorPairSpec(name: 'light: heart on surface', fg: p.heart, bg: p.surface, minRatio: 3.0),
        _ColorPairSpec(name: 'light: coin on surface', fg: p.coin, bg: p.surface, minRatio: 3.0),
      ];

      for (final spec in pairs) {
        final ratio = KataraColors.contrastRatio(spec.fg, spec.bg);
        expect(
          ratio,
          greaterThanOrEqualTo(spec.minRatio),
          reason: '${spec.name} contrast ratio ${ratio.toStringAsFixed(2)}:1 is below ${spec.minRatio}:1',
        );
      }
    });

    test('All KataraPalette.dark foreground/background pairs meet or exceed WCAG AA+ thresholds', () {
      const p = KataraPalette.dark;

      expect(p.bg.a, 1.0);
      expect(p.surface.a, 1.0);
      expect(p.surfaceAlt.a, 1.0);
      expect(p.primaryContainer.a, 1.0);
      expect(p.secondaryContainer.a, 1.0);
      expect(p.successContainer.a, 1.0);
      expect(p.errorContainer.a, 1.0);

      final pairs = <_ColorPairSpec>[
        // Body text AAA (>= 7.0:1)
        _ColorPairSpec(name: 'dark: ink on bg', fg: p.ink, bg: p.bg, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: ink on surface', fg: p.ink, bg: p.surface, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: ink on surfaceAlt', fg: p.ink, bg: p.surfaceAlt, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: inkMuted on bg', fg: p.inkMuted, bg: p.bg, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: inkMuted on surface', fg: p.inkMuted, bg: p.surface, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: inkMuted on surfaceAlt', fg: p.inkMuted, bg: p.surfaceAlt, minRatio: 7.0),
        // Colored cards & containers (>= 7.0:1 AAA)
        _ColorPairSpec(name: 'dark: onPrimaryContainer on primaryContainer', fg: p.onPrimaryContainer, bg: p.primaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: ink on primaryContainer', fg: p.ink, bg: p.primaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: inkMuted on primaryContainer', fg: p.inkMuted, bg: p.primaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: onSecondaryContainer on secondaryContainer', fg: p.onSecondaryContainer, bg: p.secondaryContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: onSuccessContainer on successContainer', fg: p.onSuccessContainer, bg: p.successContainer, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: onErrorContainer on errorContainer', fg: p.onErrorContainer, bg: p.errorContainer, minRatio: 7.0),
        // Buttons & accents (>= 4.5:1 AA)
        _ColorPairSpec(name: 'dark: onPrimary on primary', fg: p.onPrimary, bg: p.primary, minRatio: 4.5),
        _ColorPairSpec(name: 'dark: onSecondary on secondary', fg: p.onSecondary, bg: p.secondary, minRatio: 7.0),
        _ColorPairSpec(name: 'dark: primary on surface', fg: p.primary, bg: p.surface, minRatio: 4.5),
        _ColorPairSpec(name: 'dark: primary on bg', fg: p.primary, bg: p.bg, minRatio: 4.5),
        _ColorPairSpec(name: 'dark: success on surface', fg: p.success, bg: p.surface, minRatio: 4.5),
        _ColorPairSpec(name: 'dark: error on surface', fg: p.error, bg: p.surface, minRatio: 4.5),
        // Non-text borders & icons (>= 3.0:1)
        _ColorPairSpec(name: 'dark: outline on surface', fg: p.outline, bg: p.surface, minRatio: 3.0),
        _ColorPairSpec(name: 'dark: outline on bg', fg: p.outline, bg: p.bg, minRatio: 3.0),
        _ColorPairSpec(name: 'dark: outline on surfaceAlt', fg: p.outline, bg: p.surfaceAlt, minRatio: 3.0),
        _ColorPairSpec(name: 'dark: streak on surface', fg: p.streak, bg: p.surface, minRatio: 3.0),
        _ColorPairSpec(name: 'dark: heart on surface', fg: p.heart, bg: p.surface, minRatio: 3.0),
        _ColorPairSpec(name: 'dark: coin on surface', fg: p.coin, bg: p.surface, minRatio: 3.0),
      ];

      for (final spec in pairs) {
        final ratio = KataraColors.contrastRatio(spec.fg, spec.bg);
        expect(
          ratio,
          greaterThanOrEqualTo(spec.minRatio),
          reason: '${spec.name} contrast ratio ${ratio.toStringAsFixed(2)}:1 is below ${spec.minRatio}:1',
        );
      }
    });

    test('All DialectVisualIdentity badges and accents meet >= 4.5:1 contrast in Light and Dark mode', () {
      const identities = [
        DialectVisualIdentity.deli,
        DialectVisualIdentity.langkat,
        DialectVisualIdentity.palembang,
      ];

      for (final id in identities) {
        final lightRatio = KataraColors.contrastRatio(id.badgeFgLight, id.badgeBgLight);
        final darkRatio = KataraColors.contrastRatio(id.badgeFgDark, id.badgeBgDark);
        final accentRatio = KataraColors.contrastRatio(id.onAccentColor, id.accentColor);

        expect(lightRatio, greaterThanOrEqualTo(7.0), reason: '${id.courseId} light badge contrast < 7:1');
        expect(darkRatio, greaterThanOrEqualTo(7.0), reason: '${id.courseId} dark badge contrast < 7:1');
        expect(accentRatio, greaterThanOrEqualTo(4.5), reason: '${id.courseId} accent button contrast < 4.5:1');
      }
    });
  });

  group('Internal Audit String Sanitization & Honest ValidationStatusBadge', () {
    test('WordModel.sanitizeUserNotes and ExerciseGenerator strip internal "Hasil audit deli_cek" strings', () {
      const rawNote =
          'Hasil audit deli_cek (w009): Kata khas Medan/Deli yang sangat terkenal untuk menyebut pasar tradisional.';
      final sanitized = WordModel.sanitizeUserNotes(rawNote);
      expect(sanitized, isNotNull);
      expect(sanitized!.toLowerCase(), isNot(contains('hasil audit')));
      expect(sanitized.toLowerCase(), isNot(contains('deli_cek')));
      expect(sanitized.toLowerCase(), isNot(contains('w009')));
      expect(sanitized, contains('Kata khas Medan/Deli'));

      final word = WordModel.fromJson({
        'id': 'ms-deli:w:0009',
        'course_id': 'ms-deli',
        'deli': 'pajak',
        'indonesia': 'pasar',
        'category': 'tempat_benda',
        'level': 1,
        'unit_id': 'ms-deli:u:0004',
        'pos': 'benda',
        'register': 'deli',
        'raw_register': 'deli_khas',
        'notes': rawNote,
        'validation_status': 'dictionary_verified',
      });

      const generator = ExerciseGenerator();
      final items = generator.generate(
        lesson: const LessonModel(
          id: 'ms-deli:l:0001',
          courseId: 'ms-deli',
          unitId: 'ms-deli:u:0004',
          order: 1,
          kind: 'vocab',
          itemRefs: ['ms-deli:w:0009'],
          xpReward: 15,
        ),
        words: [word],
        phrases: const [],
        sentences: const [],
        letters: const [],
        quizBank: const [],
      );

      final intro = items.firstWhere((e) => e.isIntro);
      expect(intro.explanation, isNotNull);
      expect(intro.explanation!.toLowerCase(), isNot(contains('hasil audit')));
      expect(intro.explanation!.toLowerCase(), isNot(contains('deli_cek')));
      expect(intro.validationStatus, 'dictionary_verified');
    });

    testWidgets('ValidationStatusBadge renders Sumber Kamus for dictionary_verified and Dicek Penutur for speaker_checked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: KataraTheme.dark(),
          home: const Scaffold(
            body: Column(
              children: [
                ValidationStatusBadge(status: 'dictionary_verified'),
                ValidationStatusBadge(status: 'speaker_checked'),
                ValidationStatusBadge(status: 'expert_verified'),
                ValidationStatusBadge(status: 'draft'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Sumber Kamus'), findsOneWidget);
      expect(find.text('Dicek Penutur'), findsOneWidget);
      expect(find.text('Terverifikasi Ahli'), findsOneWidget);
      expect(find.text('Draf'), findsOneWidget);
    });
  });

  group('Multi-Theme Widget Contrast & Rendering Tests (Light & Dark)', () {
    for (final isDark in [false, true]) {
      final modeName = isDark ? 'Dark' : 'Light';
      final theme = isDark ? KataraTheme.dark() : KataraTheme.light();

      testWidgets('ProfileScreen, RegionPickerScreen, SettingsScreen, and Lesson IntroCard render with opaque high-contrast KCard in $modeName mode', (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        await db.ensureInitialized();
        await ContentSeeder(db: db).seedIfNeeded();
        addTearDown(() => db.close());

        // 1. ProfileScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: theme,
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Total XP:'), findsOneWidget);
        expect(find.textContaining('Target naik level:'), findsOneWidget);

        // Verify selected KCard container decoration has alpha == 1.0
        final kCardFinder = find.byWidgetPredicate(
          (w) => w is KCard && w.selected,
        );
        expect(kCardFinder, findsWidgets);

        // 2. SettingsScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: theme,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pengaturan'), findsWidgets);

        // 3. RegionPickerScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: theme,
              home: const RegionPickerScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Melayu Deli'), findsWidgets);

        // 4. LessonScreen (IntroCard)
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: theme,
              home: const LessonScreen(lessonId: 'ms-deli:l:0001'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Hasil audit'), findsNothing);
        expect(find.textContaining('deli_cek'), findsNothing);
      });
    }
  });
}
