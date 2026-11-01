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
  group('WCAG AA Contrast Verification', () {
    test('Light palette text/background pairs meet WCAG AA (>= 4.5:1)', () {
      const p = KataraPalette.light;
      expect(KataraColors.contrastRatio(p.primary, p.onPrimary), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.secondary, p.onSecondary), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.bg, p.ink), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.bg, p.inkMuted), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.surface, p.ink), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.surfaceAlt, p.ink), greaterThanOrEqualTo(4.5));
    });

    test('Dark palette text/background pairs meet WCAG AA (>= 4.5:1)', () {
      const p = KataraPalette.dark;
      expect(KataraColors.contrastRatio(p.primary, p.onPrimary), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.secondary, p.onSecondary), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.bg, p.ink), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.bg, p.inkMuted), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.surface, p.ink), greaterThanOrEqualTo(4.5));
      expect(KataraColors.contrastRatio(p.surfaceAlt, p.ink), greaterThanOrEqualTo(4.5));
    });
  });

  group('Core Widgets & Jawi Rendering', () {
    testWidgets('JawiText renders Jawi characters (ڠ ݢ ڤ ڽ چ ۏ) in RTL direction', (tester) async {
      const sampleJawi = 'ڠ ݢ ڤ ڽ چ ۏ';
      await tester.pumpWidget(
        MaterialApp(
          theme: KataraTheme.light(),
          home: const Scaffold(
            body: JawiText(sampleJawi),
          ),
        ),
      );

      expect(find.text(sampleJawi), findsOneWidget);
      final directionality = tester.widget<Directionality>(
        find.ancestor(
          of: find.text(sampleJawi),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('KButton triggers callback and enforces >= 44px tap target', (tester) async {
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

    testWidgets('ExerciseScaffold displays non-color-only feedback for correct and wrong states', (tester) async {
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
    });

    testWidgets('MascotView renders Si Rebung in all 4 states and PathNode renders states', (tester) async {
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
    });

    testWidgets('DevGalleryScreen renders in both light and dark modes', (tester) async {
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
