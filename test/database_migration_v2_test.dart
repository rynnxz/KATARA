import 'package:flutter_test/flutter_test.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/domain/entities/user_progress.dart';

void main() {
  group('AppDatabase Schema v2 & Migration Tests', () {
    test('AppDatabase reports schemaVersion 2 and creates all v2 tables', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      await db.ensureInitialized();
      expect(db.schemaVersion, 2);

      // Verify new v2 tables exist and can be queried
      final installedModules = await db
          .customSelect('SELECT * FROM installed_modules')
          .get();
      expect(installedModules, isEmpty);

      final dialectRefs = await db
          .customSelect('SELECT * FROM dialect_references')
          .get();
      expect(dialectRefs, isEmpty);

      final xpEvents = await db.customSelect('SELECT * FROM xp_events').get();
      expect(xpEvents, isEmpty);

      final streakHistory = await db
          .customSelect('SELECT * FROM streak_history')
          .get();
      expect(streakHistory, isEmpty);

      final syncQueue = await db.customSelect('SELECT * FROM sync_queue').get();
      expect(syncQueue, isEmpty);

      final userProfiles = await db
          .customSelect('SELECT * FROM user_profiles')
          .get();
      expect(userProfiles, isEmpty);

      // Verify extended columns on words & courses
      await db.customStatement(
        '''
        INSERT INTO words (
          id, course_id, deli, indonesia, category, level, unit_id, pos,
          register, raw_register, pronunciation, example_sentence,
          example_translation, usage_context, region, variants_json,
          confidence, sources_json, validation_status
        ) VALUES (
          'ms-langkat:w:0001', 'ms-langkat', 'awak', 'saya / kamu',
          'pronomina', 1, 'ms-langkat:u:0001', 'pronomina',
          'langkat', 'langkat', '[awaʔ]', 'Awak orang Tanjung Pura.',
          'Saya orang Tanjung Pura.', 'sapaan akrab', 'Tanjung Pura',
          '["awek"]', 'high', '[{"id":"SRC-LKT-01"}]', 'verified'
        )
        ''',
      );

      final wordRows = await db
          .customSelect(
            "SELECT pronunciation, region, confidence FROM words WHERE id = 'ms-langkat:w:0001'",
          )
          .get();
      expect(wordRows.single.read<String?>('pronunciation'), '[awaʔ]');
      expect(wordRows.single.read<String?>('region'), 'Tanjung Pura');
      expect(wordRows.single.read<String?>('confidence'), 'high');
    });

    test('upgradeToV2 preserves existing v1 user_stats and course_progress', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      await db.ensureInitialized();
      await db.customStatement(
        'UPDATE user_stats SET xp_total = 250, level = 3, streak_current = 5 WHERE id = 1',
      );
      await db.customStatement(
        '''
        INSERT INTO course_progress (course_id, lesson_id, stars, best_score, completed_at)
        VALUES ('ms-deli', 'ms-deli:l:0001', 3, 100, '2026-11-10T10:00:00Z')
        ''',
      );

      // Re-running upgrade logic must be idempotent and preserve user progress
      await db.runV2UpgradeSafely();

      final statsRow = await db
          .customSelect('SELECT xp_total, level, streak_current, device_id, revision FROM user_stats WHERE id = 1')
          .getSingle();
      expect(statsRow.read<int>('xp_total'), 250);
      expect(statsRow.read<int>('level'), 3);
      expect(statsRow.read<int>('streak_current'), 5);
      expect(statsRow.read<int>('revision'), greaterThanOrEqualTo(1));

      final progressRow = await db
          .customSelect("SELECT stars, best_score, is_synced FROM course_progress WHERE lesson_id = 'ms-deli:l:0001'")
          .getSingle();
      expect(progressRow.read<int>('stars'), 3);
      expect(progressRow.read<int>('best_score'), 100);
      expect(progressRow.read<int>('is_synced'), 0);
    });

    test('InstalledModuleModel, DialectReferenceModel, and XpEventModel serialize cleanly', () {
      final module = InstalledModuleModel.fromJson({
        'module_id': 'melayu_langkat',
        'course_id': 'ms-langkat',
        'version': 1,
        'is_bundled': false,
        'install_path': '/data/modules/ms-langkat',
        'sha256': 'abc123sha',
        'size_bytes': 102400,
        'installed_at': '2026-11-11T00:00:00Z',
        'updated_at': '2026-11-11T00:00:00Z',
      });
      expect(module.moduleId, 'melayu_langkat');
      expect(module.courseId, 'ms-langkat');
      expect(module.isBundled, isFalse);

      final refModel = DialectReferenceModel.fromJson({
        'id': 'SRC-LKT-0001',
        'course_id': 'ms-langkat',
        'dialect_id': 'melayu_langkat',
        'title': 'Kamus Melayu Sumatera Utara - Indonesia',
        'author': 'Balai Bahasa Sumatera Utara',
        'publication_year': 2018,
        'publisher': 'Kemendikbud',
        'source_type': 'dictionary',
        'url': 'https://repositori.kemdikbud.go.id/',
        'accessed_at': '2026-11-10',
        'reliability': 'high',
        'supported_domain': 'Kosakata Melayu Langkat & Deli',
      });
      expect(refModel.dialectId, 'melayu_langkat');
      expect(refModel.publicationYear, 2018);

      final xpEvent = XpEventModel(
        eventId: 'evt-001',
        courseId: 'ms-deli',
        amount: 15,
        source: 'lesson:ms-deli:l:0001',
        deviceId: 'dev-local-1',
        createdAt: DateTime.utc(2026, 11, 11),
      );
      expect(xpEvent.toJson()['event_id'], 'evt-001');
      expect(xpEvent.amount, 15);
    });
  });
}
