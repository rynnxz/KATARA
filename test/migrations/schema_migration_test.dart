import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/data/db/app_database.dart';

void main() {
  group('Drift Schema Migration Tests (v1 -> v2)', () {
    test('Migrates v1 database with user progress to v2 with zero data loss and idempotent re-run', () async {
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          // 1. Construct exact v1 schema (prior to v2 multi-dialect & cloud sync columns)
      rawDb.execute('''
        CREATE TABLE courses (
          id TEXT PRIMARY KEY NOT NULL,
          language_id TEXT NOT NULL,
          name TEXT NOT NULL,
          region_label TEXT NOT NULL,
          status TEXT NOT NULL,
          accent_hex TEXT NOT NULL,
          content_version INTEGER NOT NULL DEFAULT 0,
          has_jawi INTEGER NOT NULL DEFAULT 0
        );
      ''');

      rawDb.execute('''
        CREATE TABLE words (
          id TEXT PRIMARY KEY NOT NULL,
          course_id TEXT NOT NULL,
          deli TEXT NOT NULL,
          indonesia TEXT NOT NULL,
          jawi TEXT,
          category TEXT NOT NULL,
          level INTEGER NOT NULL DEFAULT 1,
          unit_id TEXT NOT NULL,
          pos TEXT NOT NULL,
          register TEXT NOT NULL,
          raw_register TEXT NOT NULL DEFAULT 'deli',
          notes TEXT,
          audio_path TEXT,
          image_path TEXT,
          validation_status TEXT NOT NULL DEFAULT 'draft',
          deprecated INTEGER NOT NULL DEFAULT 0
        );
      ''');

      rawDb.execute('''
        CREATE TABLE phrases (
          id TEXT PRIMARY KEY NOT NULL,
          course_id TEXT NOT NULL,
          deli TEXT NOT NULL,
          indonesia TEXT NOT NULL,
          jawi TEXT,
          level INTEGER NOT NULL DEFAULT 1,
          unit_id TEXT NOT NULL,
          audio_path TEXT,
          cultural_note TEXT,
          validation_status TEXT NOT NULL DEFAULT 'draft',
          deprecated INTEGER NOT NULL DEFAULT 0
        );
      ''');

      rawDb.execute('''
        CREATE TABLE sentences (
          id TEXT PRIMARY KEY NOT NULL,
          course_id TEXT NOT NULL,
          deli TEXT NOT NULL,
          indonesia TEXT NOT NULL,
          word_ids_json TEXT NOT NULL,
          level INTEGER NOT NULL DEFAULT 1,
          validation_status TEXT NOT NULL DEFAULT 'draft',
          deprecated INTEGER NOT NULL DEFAULT 0
        );
      ''');

      rawDb.execute('''
        CREATE TABLE user_stats (
          id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
          xp_total INTEGER NOT NULL DEFAULT 0,
          level INTEGER NOT NULL DEFAULT 1,
          coins INTEGER NOT NULL DEFAULT 20,
          hearts INTEGER NOT NULL DEFAULT 5,
          hearts_updated_at TEXT NOT NULL,
          streak_current INTEGER NOT NULL DEFAULT 0,
          streak_best INTEGER NOT NULL DEFAULT 0,
          last_active_date TEXT,
          streak_freezes INTEGER NOT NULL DEFAULT 1,
          daily_goal_minutes INTEGER NOT NULL DEFAULT 10,
          active_course_id TEXT,
          display_name TEXT NOT NULL DEFAULT 'Pelajar',
          learning_goal TEXT NOT NULL DEFAULT 'budaya',
          casual_mode INTEGER NOT NULL DEFAULT 0,
          onboarding_completed INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL
        );
      ''');

      rawDb.execute('''
        CREATE TABLE course_progress (
          course_id TEXT NOT NULL,
          lesson_id TEXT NOT NULL,
          stars INTEGER NOT NULL DEFAULT 0,
          best_score INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT NOT NULL,
          PRIMARY KEY (course_id, lesson_id)
        );
      ''');

      rawDb.execute('''
        CREATE TABLE word_mastery (
          course_id TEXT NOT NULL,
          item_id TEXT NOT NULL,
          item_type TEXT NOT NULL,
          strength INTEGER NOT NULL DEFAULT 0,
          correct_count INTEGER NOT NULL DEFAULT 0,
          wrong_count INTEGER NOT NULL DEFAULT 0,
          last_seen_at TEXT NOT NULL,
          next_review_at TEXT NOT NULL,
          PRIMARY KEY (course_id, item_id)
        );
      ''');

      rawDb.execute('''
        CREATE TABLE achievements_unlocked (
          achievement_id TEXT PRIMARY KEY NOT NULL,
          unlocked_at TEXT NOT NULL
        );
      ''');

      // Seed v1 user progress & content rows
      rawDb.execute('''
        INSERT INTO courses (id, language_id, name, region_label, status, accent_hex, content_version, has_jawi)
        VALUES ('ms-deli', 'ms', 'Melayu Deli', 'Medan & Deli Serdang', 'active', '#F5B700', 1, 1);
      ''');

      rawDb.execute('''
        INSERT INTO words (id, course_id, deli, indonesia, category, level, unit_id, pos, register)
        VALUES ('ms-deli:w:0001', 'ms-deli', 'encik', 'tuan/puan', 'sapaan', 1, 'ms-deli:u:0001', 'nomina', 'halus');
      ''');

      rawDb.execute('''
        INSERT INTO user_stats (
          id, xp_total, level, coins, hearts, hearts_updated_at,
          streak_current, streak_best, last_active_date, streak_freezes,
          daily_goal_minutes, active_course_id, display_name, learning_goal,
          casual_mode, onboarding_completed, updated_at
        ) VALUES (
          1, 450, 3, 110, 5, '2026-11-10T08:00:00Z',
          9, 14, '2026-11-10', 2,
          15, 'ms-deli', 'Siti Maimun', 'percakapan',
          0, 1, '2026-11-10T08:00:00Z'
        );
      ''');

      rawDb.execute('''
        INSERT INTO course_progress (course_id, lesson_id, stars, best_score, completed_at)
        VALUES ('ms-deli', 'ms-deli:l:0001', 3, 100, '2026-11-10T08:05:00Z');
      ''');

      rawDb.execute('''
        INSERT INTO word_mastery (
          course_id, item_id, item_type, strength, correct_count, wrong_count, last_seen_at, next_review_at
        ) VALUES (
          'ms-deli', 'ms-deli:w:0001', 'word', 4, 8, 1, '2026-11-10T08:05:00Z', '2026-11-14T08:05:00Z'
        );
      ''');

      rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      // 2. Open with Drift AppDatabase (schemaVersion 2) & run v1 -> v2 upgrade
      final appDb = AppDatabase(executor);
      addTearDown(appDb.close);

      await appDb.runV2UpgradeSafely();
      // Run a second time to verify 100% idempotency
      await appDb.runV2UpgradeSafely();

      // 3. Verify v1 user progress is 100% intact and v2 columns have expected defaults
      final statsRows = await appDb.customSelect('SELECT * FROM user_stats WHERE id = 1').get();
      expect(statsRows, hasLength(1));
      final stats = statsRows.first;
      expect(stats.read<int>('xp_total'), equals(450));
      expect(stats.read<int>('level'), equals(3));
      expect(stats.read<int>('coins'), equals(110));
      expect(stats.read<int>('streak_current'), equals(9));
      expect(stats.read<int>('streak_best'), equals(14));
      expect(stats.read<String>('display_name'), equals('Siti Maimun'));
      expect(stats.read<String>('device_id'), equals('local-device'));
      expect(stats.read<int>('revision'), equals(1));
      expect(stats.read<int>('is_synced'), equals(0));

      final progRows = await appDb.customSelect(
        "SELECT * FROM course_progress WHERE course_id = 'ms-deli' AND lesson_id = 'ms-deli:l:0001'",
      ).get();
      expect(progRows, hasLength(1));
      expect(progRows.first.read<int>('stars'), equals(3));
      expect(progRows.first.read<int>('best_score'), equals(100));
      expect(progRows.first.read<String>('device_id'), equals('local-device'));
      expect(progRows.first.read<int>('revision'), equals(1));

      final masteryRows = await appDb.customSelect(
        "SELECT * FROM word_mastery WHERE course_id = 'ms-deli' AND item_id = 'ms-deli:w:0001'",
      ).get();
      expect(masteryRows, hasLength(1));
      expect(masteryRows.first.read<int>('strength'), equals(4));
      expect(masteryRows.first.read<int>('correct_count'), equals(8));
      expect(masteryRows.first.read<String>('device_id'), equals('local-device'));

      // 4. Verify v2 tables exist and are operational
      for (final table in const [
        'installed_modules',
        'dialect_references',
        'xp_events',
        'streak_history',
        'sync_queue',
        'user_profiles',
      ]) {
        final countRow = await appDb.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
        expect(countRow.read<int>('c'), equals(0));
      }
    });
  });
}
