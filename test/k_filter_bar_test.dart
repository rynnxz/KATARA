import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/app/widgets/k_filter_bar.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/features/dialect_comparison/dialect_comparison_screen.dart';
import 'package:katara/features/dictionary/dictionary_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KFilterBar & Category Chip Layout Tests (B4)', () {
    testWidgets(
      'KFilterBar supports multi-category selection, Semua reset, Lainnya (+N) expansion, and zero overflow across screen sizes & text scales',
      (tester) async {
        var selected = <String>{};
        var resetCalled = false;

        const categories = [
          KFilterCategory(id: 'semua', label: 'Semua', count: 84),
          KFilterCategory(id: 'sapaan', label: 'Sapaan', count: 12),
          KFilterCategory(id: 'keluarga', label: 'Keluarga', count: 8),
          KFilterCategory(id: 'kuliner', label: 'Kuliner', count: 15),
          KFilterCategory(id: 'pasar', label: 'Pasar', count: 10),
          KFilterCategory(id: 'waktu', label: 'Waktu', count: 6),
          KFilterCategory(id: 'tempat', label: 'Tempat', count: 9),
          KFilterCategory(id: 'angka', label: 'Angka', count: 10),
          KFilterCategory(id: 'percakapan', label: 'Percakapan', count: 14),
        ];

        Widget buildHarness({
          Size size = const Size(360, 800),
          double textScale = 1.0,
        }) {
          return MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: MaterialApp(
              theme: KataraTheme.light(),
              home: StatefulBuilder(
                builder: (context, setState) {
                  return Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: KFilterBar(
                        categories: categories,
                        selectedIds: selected,
                        totalCount: 84,
                        filteredCount: selected.isEmpty ? 84 : 20,
                        collapsedCategoryLimit: 6,
                        itemUnitLabel: 'entri',
                        onSelectionChanged: (next) {
                          setState(() {
                            selected = next;
                          });
                        },
                        onResetAll: () {
                          setState(() {
                            selected = <String>{};
                            resetCalled = true;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        // Test responsive sizes & textScaler (1.0x, 1.3x, 2.0x) on 320x568, 360x800, 412x915
        for (final size in const [
          Size(320, 568),
          Size(360, 800),
          Size(412, 915),
        ]) {
          for (final scale in const [1.0, 1.3, 2.0]) {
            await tester.pumpWidget(buildHarness(size: size, textScale: scale));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }

        // Reset to standard viewport for interaction assertions
        await tester.pumpWidget(buildHarness());
        await tester.pumpAndSettle();

        expect(find.text('Semua (84)'), findsOneWidget);
        expect(find.text('Sapaan (12)'), findsOneWidget);
        expect(find.text('Lainnya (+3)'), findsOneWidget);

        // Expand Lainnya (+3)
        await tester.tap(find.text('Lainnya (+3)'));
        await tester.pumpAndSettle();
        expect(find.text('Percakapan (14)'), findsOneWidget);
        expect(find.text('Ringkas'), findsOneWidget);

        // Select two categories simultaneously (multi-select)
        await tester.tap(find.text('Sapaan (12)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kuliner (15)'));
        await tester.pumpAndSettle();

        expect(selected, containsAll(['sapaan', 'kuliner']));
        expect(find.text('Menampilkan 20 dari 84 entri'), findsOneWidget);
        expect(find.text('Atur ulang filter'), findsOneWidget);

        // Tap Atur ulang filter -> clears selection
        await tester.tap(find.text('Atur ulang filter'));
        await tester.pumpAndSettle();
        expect(selected, isEmpty);
        expect(resetCalled, isTrue);
      },
    );

    testWidgets(
      'DialectComparisonScreen & DictionaryScreen filter by category + search and render Palembang phonetics without overflow',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await tester.runAsync(() async {
          await db.ensureInitialized();
          await ContentSeeder(db: db).seedIfNeeded();
        });

        Widget wrapScreen(
          Widget screen, {
          Size size = const Size(320, 640),
          double textScale = 1.3,
        }) {
          return ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: MaterialApp(theme: KataraTheme.light(), home: screen),
            ),
          );
        }

        await tester.pumpWidget(wrapScreen(const DialectComparisonScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Semua ('), findsOneWidget);
        expect(find.textContaining('Menampilkan '), findsOneWidget);

        // Search debounce (180ms)
        await tester.enterText(find.byType(TextField), 'apo');
        await tester.pump(const Duration(milliseconds: 220));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('apo'), findsWidgets);

        // Test DictionaryScreen at narrow width + 1.3x text scale
        await tester.pumpWidget(wrapScreen(const DictionaryScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Semua ('), findsOneWidget);
      },
    );
  });
}
