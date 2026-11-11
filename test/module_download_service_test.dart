import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/data/repositories/local_content_repository.dart';
import 'package:katara/services/module_download_service.dart';

void main() {
  late AppDatabase db;
  late ContentSeeder seeder;
  late LocalContentRepository contentRepo;
  late Directory tempInstallRoot;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureInitialized();
    seeder = ContentSeeder(
      db: db,
      loadAsset: (assetPath) async => File(assetPath).readAsStringSync(),
    );
    await seeder.seedIfNeeded(force: true);
    contentRepo = LocalContentRepository(db: db);
    tempInstallRoot = await Directory.systemTemp.createTemp('katara_mod_test_');
  });

  tearDown(() async {
    await db.close();
    if (tempInstallRoot.existsSync()) {
      await tempInstallRoot.delete(recursive: true);
    }
  });

  group('Downloadable Dialect Module Manager & Seeder Tests', () {
    test('Install module_langkat.zip and module_palembang.zip activates courses and seeds >= 300 words & references', () async {
      final service = ModuleDownloadService(
        db: db,
        seeder: seeder,
        installRootDirectoryProvider: () async => tempInstallRoot,
      );

      final catalog = await service.loadCatalog();
      expect(catalog.length, greaterThanOrEqualTo(2));

      final langkatItem = catalog.firstWhere((m) => m.courseId == 'ms-langkat');
      final progressValues = <double>[];

      final installed = await service.installModule(
        langkatItem,
        onProgress: progressValues.add,
      );

      expect(installed.courseId, equals('ms-langkat'));
      expect(installed.wordCount, greaterThanOrEqualTo(300));
      expect(progressValues, isNotEmpty);
      expect(progressValues.last, equals(1.0));

      final course = await contentRepo.getCourse('ms-langkat');
      expect(course, isNotNull);
      expect(course!.status, equals('active'));

      final words = await contentRepo.getWords('ms-langkat');
      expect(words.length, greaterThanOrEqualTo(300));
      expect(words.first.pronunciation, isNotEmpty);

      final refs = await contentRepo.getDialectReferences('ms-langkat');
      expect(refs.length, greaterThanOrEqualTo(5));

      final palembangItem = catalog.firstWhere(
        (m) => m.courseId == 'ms-palembang',
      );
      await service.installModule(palembangItem);

      final palembangWords = await contentRepo.getWords('ms-palembang');
      expect(palembangWords.length, greaterThanOrEqualTo(300));

      final comparisonRows = await contentRepo.getDialectComparisonRows();
      expect(comparisonRows.length, greaterThanOrEqualTo(15));
    });

    test('Corrupted SHA-256 or path-traversal ZIP entries are rejected before touching DB', () async {
      final service = ModuleDownloadService(
        db: db,
        seeder: seeder,
        installRootDirectoryProvider: () async => tempInstallRoot,
        bytesFetcher: (item, onProgress) async {
          return Uint8List.fromList(utf8.encode('corrupted-zip-bytes'));
        },
      );

      final catalog = await service.loadCatalog();
      final langkatItem = catalog.firstWhere((m) => m.courseId == 'ms-langkat');

      await expectLater(
        () => service.installModule(langkatItem),
        throwsA(isA<ModuleDownloadException>()),
      );

      // Now test path traversal ZIP with valid matching SHA-256
      final maliciousArchive = Archive()
        ..addFile(ArchiveFile('../evil.json', 2, utf8.encode('{}')));
      final maliciousBytes = Uint8List.fromList(
        ZipEncoder().encode(maliciousArchive),
      );

      await expectLater(
        () => service.verifyAndExtractArchive(
          zipBytes: maliciousBytes,
          expectedSha256: null,
          targetDir: Directory('${tempInstallRoot.path}/evil_target'),
        ),
        throwsA(isA<ModuleDownloadException>()),
      );
    });

    test('Uninstalling a module deletes content rows and files while preserving user progress and XP', () async {
      final service = ModuleDownloadService(
        db: db,
        seeder: seeder,
        installRootDirectoryProvider: () async => tempInstallRoot,
      );

      final catalog = await service.loadCatalog();
      final langkatItem = catalog.firstWhere((m) => m.courseId == 'ms-langkat');
      await service.installModule(langkatItem);

      // Insert user progress & mastery for ms-langkat
      await db.customStatement('''
        INSERT INTO course_progress (course_id, lesson_id, stars, best_score, completed_at, updated_at)
        VALUES ('ms-langkat', 'ms-langkat:l:0001', 3, 100, '2026-11-11T00:00:00Z', '2026-11-11T00:00:00Z')
        ''');
      await db.customStatement('''
        INSERT INTO word_mastery (course_id, item_id, item_type, strength, correct_count, wrong_count, last_seen_at, next_review_at)
        VALUES ('ms-langkat', 'ms-langkat:w:0001', 'word', 3, 3, 0, '2026-11-11T00:00:00Z', '2026-11-14T00:00:00Z')
        ''');

      await service.uninstallModule('ms-langkat');

      final wordsAfter = await contentRepo.getWords('ms-langkat');
      expect(wordsAfter, isEmpty);

      final courseAfter = await contentRepo.getCourse('ms-langkat');
      expect(courseAfter!.status, equals('downloadable'));

      // Verify user progress and word mastery are preserved
      final progressRows = await db
          .customSelect(
            "SELECT * FROM course_progress WHERE course_id = 'ms-langkat'",
          )
          .get();
      expect(progressRows.length, equals(1));

      final masteryRows = await db
          .customSelect(
            "SELECT * FROM word_mastery WHERE course_id = 'ms-langkat'",
          )
          .get();
      expect(masteryRows.length, equals(1));
    });
  });
}
