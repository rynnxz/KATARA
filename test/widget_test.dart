import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/app.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/features/region_picker/region_picker_screen.dart';
import 'package:katara/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('KATARA app boots through Splash into Onboarding offline',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider
              .overrideWithValue(NoopNotificationService()),
        ],
        child: const KataraApp(),
      ),
    );

    // Frame pertama menampilkan KATARA di Splash.
    expect(find.text('KATARA'), findsOneWidget);
    await tester.pumpAndSettle();

    // Setelah ContentSeeder selesai untuk pengguna baru, diarahkan ke Onboarding.
    expect(find.text('Kenali Bahasa Melayu Serumpun'), findsOneWidget);
  });

  testWidgets(
      'RegionPickerScreen displays active Melayu Deli and locked coming_soon card (Bagian 11.2 & 16)',
      (tester) async {
    CourseModel? selectedCourse;

    const languages = [
      LanguageModel(
        id: 'ms',
        name: 'Melayu',
        tagline: 'Bahasa serumpun Nusantara',
        order: 1,
      ),
    ];

    const courses = [
      CourseModel(
        id: 'ms-deli',
        languageId: 'ms',
        name: 'Melayu Deli',
        regionLabel: 'Medan & Sumatera Utara',
        status: 'active',
        accentHex: '#F5B700',
        contentVersion: 1,
        hasJawi: true,
      ),
      CourseModel(
        id: 'ms-other',
        languageId: 'ms',
        name: 'Melayu lainnya',
        regionLabel: 'Segera hadir',
        status: 'coming_soon',
        accentHex: '#9AA0A6',
        contentVersion: 0,
        hasJawi: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: KataraTheme.light(),
          home: Scaffold(
            body: RegionPickerScreen(
              overrideLanguages: languages,
              overrideCourses: courses,
              overrideCourseCompletionRatio: const {'ms-deli': 0.25},
              onCourseSelected: (course) => selectedCourse = course,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rumpun Bahasa: Melayu'), findsOneWidget);
    expect(find.text('Melayu Deli'), findsOneWidget);
    expect(find.text('25% selesai'), findsOneWidget);
    expect(find.text('Melayu lainnya'), findsOneWidget);
    expect(find.text('Segera hadir'), findsWidgets);

    // Ketuk kartu coming_soon -> muncul bottom sheet "Melayu lainnya Segera Hadir", tidak memilih course.
    await tester.ensureVisible(find.text('Melayu lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Melayu lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Melayu lainnya Segera Hadir'), findsOneWidget);
    expect(selectedCourse, isNull);

    await tester.ensureVisible(find.text('Mengerti'));
    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();

    // Ketuk tombol Lanjut pada Melayu Deli -> memilih course aktif.
    await tester.ensureVisible(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(selectedCourse?.id, equals('ms-deli'));
  });
}
