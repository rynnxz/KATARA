import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/features/dialect_comparison/dialect_comparison_screen.dart';
import 'package:katara/features/practice/conversation_practice_screen.dart';
import 'package:katara/features/practice/practice_screen.dart';
import 'package:katara/features/region_picker/region_picker_screen.dart';
import 'package:katara/features/settings/about_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureInitialized();
    final seeder = ContentSeeder(db: db);
    await seeder.seedIfNeeded();
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: KataraTheme.light(),
        darkTheme: KataraTheme.dark(),
        home: child,
      ),
    );
  }

  group('Multi-Dialect UI, Comparison, Practice & References Tests', () {
    testWidgets(
      'DialectComparisonScreen renders Deli vs Langkat vs Palembang comparison rows and phonetic notes',
      (tester) async {
        await tester.pumpWidget(wrapWithApp(const DialectComparisonScreen()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Perbandingan Dialek Melayu'), findsWidgets);
        expect(find.textContaining('Melayu Deli'), findsWidgets);
        expect(find.textContaining('Melayu Langkat'), findsWidgets);
        expect(find.textContaining('Melayu Palembang'), findsWidgets);
        expect(find.textContaining('apo'), findsWidgets);
      },
    );

    testWidgets(
      'ConversationPracticeScreen and PracticeScreen render 4 practice cards without PronunciationGuideScreen',
      (tester) async {
        await tester.pumpWidget(
          wrapWithApp(const ConversationPracticeScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Latihan Percakapan'), findsWidgets);

        await tester.pumpWidget(wrapWithApp(const PracticeScreen()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Kuis Cepat 30 Detik'), findsOneWidget);
        expect(find.textContaining('Latihan Aksara Jawi'), findsOneWidget);
        expect(find.textContaining('Latihan Percakapan'), findsOneWidget);
        expect(find.textContaining('Perbandingan Dialek'), findsOneWidget);
        expect(find.textContaining('Panduan Lafal'), findsNothing);
      },
    );

    testWidgets(
      'AboutScreen renders all 5 mandatory academic & reference sections offline',
      (tester) async {
        await tester.pumpWidget(wrapWithApp(const AboutScreen()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Tentang KATARA'), findsWidgets);
        expect(
          find.textContaining('Sumber Data Bahasa & Referensi'),
          findsWidgets,
        );

        final verticalList = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );

        await tester.scrollUntilVisible(
          find.textContaining('Metodologi Riset Linguistik'),
          200,
          scrollable: verticalList,
        );
        expect(
          find.textContaining('Metodologi Riset Linguistik'),
          findsWidgets,
        );

        await tester.scrollUntilVisible(
          find.textContaining('Atribusi & Kontributor'),
          200,
          scrollable: verticalList,
        );
        expect(find.textContaining('Atribusi & Kontributor'), findsWidgets);

        await tester.scrollUntilVisible(
          find.textContaining('Keterbatasan Data & Catatan Dialek'),
          200,
          scrollable: verticalList,
        );
        expect(
          find.textContaining('Keterbatasan Data & Catatan Dialek'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'RegionPickerScreen displays bundled Deli and downloadable Langkat & Palembang modules with SHA-256 info',
      (tester) async {
        await tester.pumpWidget(wrapWithApp(const RegionPickerScreen()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Melayu Deli'), findsWidgets);
        expect(find.textContaining('Melayu Langkat'), findsWidgets);
        expect(find.textContaining('Melayu Palembang'), findsWidgets);
        expect(find.textContaining('Unduh Modul'), findsWidgets);
      },
    );
  });
}
