import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/app.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/data/repositories/local_content_repository.dart';
import 'package:katara/data/repositories/local_progress_repository.dart';
import 'package:katara/services/firebase_sync_service.dart';
import 'package:katara/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingCloudSyncGateway extends InMemoryCloudSyncGateway {
  @override
  Future<CloudProfile> signInWithGoogle() async {
    throw PlatformException(
      code: 'network_error',
      message: 'Tidak ada koneksi internet',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WelcomeScreen & Splash Routing Flow Tests (B2)', () {
    testWidgets(
      '(a) Pengguna baru -> /welcome -> ketuk Lanjut sebagai Tamu -> masuk /onboarding dengan authMode = guest',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase.memory();
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              notificationServiceProvider.overrideWithValue(
                NoopNotificationService(),
              ),
            ],
            child: const KataraApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Selamat Datang di KATARA'), findsOneWidget);
        expect(find.text('Masuk dengan Google'), findsOneWidget);
        expect(find.text('Lanjut sebagai Tamu'), findsOneWidget);

        await tester.ensureVisible(find.text('Lanjut sebagai Tamu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lanjut sebagai Tamu'));
        await tester.pumpAndSettle();

        expect(find.text('Kenali Bahasa Melayu Serumpun'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('katara.auth_mode'), equals('guest'));
      },
    );

    testWidgets(
      '(b) Pengguna baru -> /welcome -> ketuk Masuk dengan Google -> sukses -> masuk /onboarding dengan authMode = google',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase.memory();
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              notificationServiceProvider.overrideWithValue(
                NoopNotificationService(),
              ),
              firebaseSyncServiceProvider.overrideWithValue(
                FirebaseSyncService(
                  db: db,
                  gateway: InMemoryCloudSyncGateway(),
                ),
              ),
            ],
            child: const KataraApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Selamat Datang di KATARA'), findsOneWidget);
        await tester.ensureVisible(find.text('Masuk dengan Google'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Masuk dengan Google'));
        await tester.pumpAndSettle();

        expect(find.text('Kenali Bahasa Melayu Serumpun'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('katara.auth_mode'), equals('google'));
      },
    );

    testWidgets(
      '(c) Pengguna baru -> /welcome -> ketuk Masuk dengan Google -> gagal jaringan -> tampil pesan ramah + tetap bisa Lanjut sebagai Tamu',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase.memory();
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              notificationServiceProvider.overrideWithValue(
                NoopNotificationService(),
              ),
              firebaseSyncServiceProvider.overrideWithValue(
                FirebaseSyncService(
                  db: db,
                  gateway: _FailingCloudSyncGateway(),
                ),
              ),
            ],
            child: const KataraApp(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Masuk dengan Google'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Masuk dengan Google'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Tetap di /welcome dengan pesan ramah tanpa PlatformException mentah.
        expect(find.text('Selamat Datang di KATARA'), findsOneWidget);
        expect(find.textContaining('Koneksi internet terputus'), findsWidgets);
        expect(find.textContaining('PlatformException'), findsNothing);

        // Pengguna tetap bisa memilih Lanjut sebagai Tamu.
        await tester.ensureVisible(find.text('Lanjut sebagai Tamu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lanjut sebagai Tamu'));
        await tester.pumpAndSettle();
        expect(find.text('Kenali Bahasa Melayu Serumpun'), findsOneWidget);
      },
    );

    testWidgets(
      '(d) Pengguna lama yang sudah selesai onboarding -> tidak melihat /welcome lagi, langsung ke /home/learn',
      (tester) async {
        SharedPreferences.setMockInitialValues({'katara.auth_mode': 'guest'});
        final db = AppDatabase.memory();
        addTearDown(db.close);

        await tester.runAsync(() async {
          await db.ensureInitialized();
          await ContentSeeder(db: db).seedIfNeeded();
          final contentRepo = LocalContentRepository(db: db);
          final progressRepo = LocalProgressRepository(
            db: db,
            contentRepository: contentRepo,
          );
          await progressRepo.updateProfile(
            displayName: 'Budi',
            onboardingCompleted: true,
            activeCourseId: 'ms-deli',
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              notificationServiceProvider.overrideWithValue(
                NoopNotificationService(),
              ),
            ],
            child: const KataraApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Selamat Datang di KATARA'), findsNothing);
        expect(find.text('Langkah Berikutnya'), findsOneWidget);
      },
    );
  });
}
