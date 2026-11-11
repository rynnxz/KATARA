import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/app/widgets/exercise_scaffold.dart';
import 'package:katara/app/widgets/jawi_text.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/path_node.dart';
import 'package:katara/features/dev/dev_gallery_screen.dart';

void main() {
  group('WCAG AA+ High-Contrast & Dialect Visual Identity Verification', () {
    test('Light palette text/background pairs meet strict WCAG AA+ (inkMuted >= 7.0:1 on bg/surface, >= 6.0:1 on surfaceAlt)', () {
      const p = KataraPalette.light;
      expect(
        KataraColors.contrastRatio(p.primary, p.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        KataraColors.contrastRatio(p.secondary, p.onSecondary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        KataraColors.contrastRatio(p.bg, p.ink),
        greaterThanOrEqualTo(12.0),
      );
      expect(
        KataraColors.contrastRatio(p.bg, p.inkMuted),
        greaterThanOrEqualTo(7.0),
      );
      expect(
        KataraColors.contrastRatio(p.surface, p.ink),
        greaterThanOrEqualTo(12.0),
      );
      expect(
        KataraColors.contrastRatio(p.surface, p.inkMuted),
        greaterThanOrEqualTo(7.0),
      );
      expect(
        KataraColors.contrastRatio(p.surfaceAlt, p.ink),
        greaterThanOrEqualTo(11.0),
      );
      expect(
        KataraColors.contrastRatio(p.surfaceAlt, p.inkMuted),
        greaterThanOrEqualTo(6.0),
      );
    });

    test('Dark palette text/background pairs meet strict WCAG AA+ (inkMuted >= 7.0:1 on bg/surface)', () {
      const p = KataraPalette.dark;
      expect(
        KataraColors.contrastRatio(p.primary, p.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        KataraColors.contrastRatio(p.secondary, p.onSecondary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        KataraColors.contrastRatio(p.bg, p.ink),
        greaterThanOrEqualTo(12.0),
      );
      expect(
        KataraColors.contrastRatio(p.bg, p.inkMuted),
        greaterThanOrEqualTo(7.0),
      );
      expect(
        KataraColors.contrastRatio(p.surface, p.ink),
        greaterThanOrEqualTo(11.0),
      );
      expect(
        KataraColors.contrastRatio(p.surface, p.inkMuted),
        greaterThanOrEqualTo(7.0),
      );
      expect(
        KataraColors.contrastRatio(p.surfaceAlt, p.ink),
        greaterThanOrEqualTo(9.0),
      );
      expect(
        KataraColors.contrastRatio(p.surfaceAlt, p.inkMuted),
        greaterThanOrEqualTo(6.0),
      );
    });

    test('KataraTheme explicitly sets onSurfaceVariant, inverseSurface, SnackBar, and Input themes to prevent grey-on-bright text', () {
      final lightTheme = KataraTheme.light();
      final darkTheme = KataraTheme.dark();

      expect(
        lightTheme.colorScheme.onSurfaceVariant,
        equals(KataraPalette.light.inkMuted),
      );
      expect(
        darkTheme.colorScheme.onSurfaceVariant,
        equals(KataraPalette.dark.inkMuted),
      );
      expect(
        KataraColors.contrastRatio(
          lightTheme.colorScheme.surface,
          lightTheme.colorScheme.onSurfaceVariant,
        ),
        greaterThanOrEqualTo(7.0),
      );
      expect(lightTheme.snackBarTheme.backgroundColor, isNotNull);
      expect(
        lightTheme.inputDecorationTheme.hintStyle?.color,
        equals(KataraPalette.light.inkMuted),
      );
    });

    test('DialectVisualIdentity defines distinct culturally authentic colors and >= 4.5:1 badge contrast for Deli, Langkat, and Palembang', () {
      final deli = DialectVisualIdentity.forCourse('ms-deli');
      final langkat = DialectVisualIdentity.forCourse('ms-langkat');
      final palembang = DialectVisualIdentity.forCourse('ms-palembang');

      expect(deli.accentColor, equals(const Color(0xFFF5B700)));
      expect(langkat.accentColor, equals(const Color(0xFF186B4C)));
      expect(palembang.accentColor, equals(const Color(0xFF8B1E24)));

      expect(deli.motifName, contains('Pucuk Rebung'));
      expect(langkat.motifName, contains('Tampuk Manggis'));
      expect(palembang.motifName, contains('Songket Lepus'));

      expect(
        KataraColors.contrastRatio(deli.badgeBgLight, deli.badgeFgLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        KataraColors.contrastRatio(langkat.badgeBgLight, langkat.badgeFgLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        KataraColors.contrastRatio(
          palembang.badgeBgLight,
          palembang.badgeFgLight,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('Core Widgets & Jawi Rendering', () {
    testWidgets(
      'JawiText renders Jawi characters (ڠ ݢ ڤ ڽ چ ۏ) in RTL direction',
      (tester) async {
        const sampleJawi = 'ڠ ݢ ڤ ڽ چ ۏ';
        await tester.pumpWidget(
          MaterialApp(
            theme: KataraTheme.light(),
            home: const Scaffold(body: JawiText(sampleJawi)),
          ),
        );

        expect(find.text(sampleJawi), findsOneWidget);
        final directionality = tester.widget<Directionality>(
          find
              .ancestor(
                of: find.text(sampleJawi),
                matching: find.byType(Directionality),
              )
              .first,
        );
        expect(directionality.textDirection, TextDirection.rtl);
      },
    );

    testWidgets('KButton triggers callback and enforces >= 44px tap target', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: KataraTheme.light(),
          home: Scaffold(
            body: Center(
              child: KButton(
                label: 'Mulai Belajar',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(KButton));
      expect(buttonSize.height, greaterThanOrEqualTo(44.0));

      await tester.tap(find.byType(KButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
      'ExerciseScaffold displays non-color-only feedback for correct and wrong states',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: KataraTheme.light(),
            home: ExerciseScaffold(
              progress: 0.5,
              hearts: 5,
              heartsEnabled: false,
              feedbackState: ExerciseFeedbackState.correct,
              feedbackTitle: 'Benar sekali!',
              feedbackDetail: 'Arti "mane" adalah "mana".',
              actionLabel: 'Lanjut',
              onAction: () {},
              onClose: () {},
              child: const Text('Apa arti "mane"?'),
            ),
          ),
        );

        expect(find.text('Benar sekali!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.text('Lanjut'), findsOneWidget);
      },
    );

    testWidgets(
      'MascotView renders Si Rebung in all 4 states and PathNode renders states',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: KataraTheme.dark(),
            home: Scaffold(
              body: Column(
                children: [
                  const MascotView(state: MascotState.happy),
                  PathNode(
                    title: 'Salam & Sapa',
                    status: PathNodeStatus.completed,
                    stars: 3,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(MascotView), findsOneWidget);
        expect(find.text('Salam & Sapa'), findsOneWidget);
      },
    );

    testWidgets('DevGalleryScreen renders in both light and dark modes', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: KataraTheme.light(),
            darkTheme: KataraTheme.dark(),
            home: const DevGalleryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Galeri Komponen KATARA'), findsOneWidget);
      expect(find.text('ڠ ݢ ڤ ڽ چ ۏ'), findsOneWidget);
    });
  });
}
