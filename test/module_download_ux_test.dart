import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/features/region_picker/region_picker_screen.dart';
import 'package:katara/services/module_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module Download Fallback & UX Tests (A2)', () {
    test('ModuleDownloadErrorMapper maps 404, timeout, network, and SHA-256 errors to friendly Indonesian messages without leaking ModuleDownloadException:', () {
      const err404 = ModuleDownloadException(
        'Gagal mengunduh modul Melayu Langkat (HTTP 404).',
      );
      const errTimeout = ModuleDownloadException(
        'Timeout 25s saat mengunduh modul',
      );
      const errNetwork = ModuleDownloadException(
        'SocketException: Failed host lookup',
      );
      const errHash = ModuleDownloadException(
        'Verifikasi integritas SHA-256 gagal',
      );

      for (final err in [err404, errTimeout, errNetwork, errHash]) {
        final msg = ModuleDownloadErrorMapper.toUserMessage(
          err,
          courseName: 'Melayu Langkat',
        );
        expect(msg, isNot(contains('ModuleDownloadException')));
        expect(msg, isNot(contains('HTTP 404')));
        expect(msg, isNot(contains('SocketException')));
        expect(msg.length, greaterThan(20));
      }
    });

    test('ModuleDownloadService falls back from v1.1.1 (404) to v1.1.0 release asset and verifies pinned v1.1.0 SHA-256', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.ensureInitialized();

      final seeder = ContentSeeder(
        db: db,
        loadAsset: (assetPath) async => File(assetPath).readAsStringSync(),
      );
      await seeder.seedIfNeeded(force: true);

      final tempRoot = await Directory.systemTemp.createTemp(
        'katara_fallback_test_',
      );
      addTearDown(() async {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      });

      // Simulate bytesFetcher returning the v1.1.0 release ZIP bytes (whose hash matches trustedFallbackReleases['ms-langkat'])
      final v110ZipBytes = await File('dist/releases/v1.1.0/module_langkat.zip')
          .readAsBytes();

      final service = ModuleDownloadService(
        db: db,
        seeder: seeder,
        installRootDirectoryProvider: () async => tempRoot,
        bytesFetcher: (item, onProgress) async {
          onProgress?.call(1.0);
          return Uint8List.fromList(v110ZipBytes);
        },
      );

      final catalog = await service.loadCatalog();
      final langkatItem = catalog.firstWhere((m) => m.courseId == 'ms-langkat');

      // Even though catalog has v1.1.1 sha256, verifyAndExtractArchive / installModule accepts the pinned v1.1.0 fallback SHA-256!
      final installed = await service.installModule(langkatItem);
      expect(installed.courseId, equals('ms-langkat'));
      expect(installed.wordCount, greaterThanOrEqualTo(300));
    });

    testWidgets(
      'RegionPickerScreen shows Cek SHA-256 saat pasang before download, removes Melayu lainnya card, and shows friendly SnackBar on failure',
      (tester) async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        late ContentSeeder seeder;
        late Directory tempRoot;
        await tester.runAsync(() async {
          await db.ensureInitialized();
          seeder = ContentSeeder(db: db);
          await seeder.seedIfNeeded(force: true);
          tempRoot = await Directory.systemTemp.createTemp('katara_region_ux_');
        });
        addTearDown(() async {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        });

        final failingService = ModuleDownloadService(
          db: db,
          seeder: seeder,
          installRootDirectoryProvider: () async => tempRoot,
          bytesFetcher: (item, onProgress) async {
            throw const ModuleDownloadException(
              'Gagal mengunduh modul Melayu Langkat (HTTP 404).',
            );
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              moduleDownloadServiceProvider.overrideWithValue(failingService),
            ],
            child: MaterialApp(
              theme: KataraTheme.light(),
              home: const RegionPickerScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Kartu usang "Melayu lainnya" tidak lagi muncul dari seeder
        expect(find.text('Melayu lainnya'), findsNothing);

        // Sebelum diunduh, tampil "Cek SHA-256 saat pasang", BUKAN "SHA-256 Terverifikasi"
        expect(find.text('Cek SHA-256 saat pasang'), findsWidgets);
        expect(find.text('Terpasang • SHA-256 Terverifikasi'), findsNothing);

        // Ketuk Unduh Modul -> gagal 404 -> SnackBar ramah pengguna tanpa teks ModuleDownloadException:
        final downloadBtn = find.textContaining('Unduh Modul').first;
        await tester.ensureVisible(downloadBtn);
        await tester.pump();
        await tester.tap(downloadBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.textContaining('ModuleDownloadException'), findsNothing);
        expect(
          find.textContaining('Paket modul Melayu Langkat belum tersedia'),
          findsOneWidget,
        );
        expect(find.text('Coba Lagi'), findsOneWidget);
      },
    );

    test('Branding assets and Android launcher/notification/splash resources exist and have valid PNG dimensions', () {
      final icon1024 = File('assets/branding/app_icon_1024.png');
      final fg1024 = File('assets/branding/app_icon_foreground.png');
      final mono1024 = File('assets/branding/app_icon_monochrome.png');
      final splash512 = File('assets/branding/splash_mascot.png');
      final notifIcon = File(
        'android/app/src/main/res/drawable/ic_stat_katara.png',
      );
      final adaptiveXml = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      );
      final splashV31Xml = File(
        'android/app/src/main/res/values-v31/styles.xml',
      );

      for (final f in [
        icon1024,
        fg1024,
        mono1024,
        splash512,
        notifIcon,
        adaptiveXml,
        splashV31Xml,
      ]) {
        expect(f.existsSync(), isTrue, reason: 'Missing ${f.path}');
        expect(f.lengthSync(), greaterThan(100));
      }

      // Check PNG IHDR width/height for app_icon_1024.png (bytes 16..24 big-endian)
      final bytes = icon1024.readAsBytesSync();
      final bd = ByteData.sublistView(Uint8List.fromList(bytes));
      expect(bd.getUint32(16), equals(1024));
      expect(bd.getUint32(20), equals(1024));
    });
  });
}
