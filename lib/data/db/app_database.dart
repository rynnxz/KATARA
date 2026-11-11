import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:katara/data/db/connection_stub.dart'
    if (dart.library.ffi) 'package:katara/data/db/connection_native.dart'
    if (dart.library.js_interop) 'package:katara/data/db/connection_web.dart';

/// Database SQLite lokal KATARA menggunakan `drift` (schemaVersion 2).
/// Mencakup tabel konten multi-dialek, modul unduhan, referensi akademik,
/// progres lokal, event ledger XP idempoten, dan antrean sinkronisasi cloud.
class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'katara_db',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  factory AppDatabase.memory() => AppDatabase(openMemoryConnection());

  final StreamController<String> _changeController =
      StreamController<String>.broadcast();

  Stream<String> get tableChanges => _changeController.stream;

  void notifyTableChanged(String table) {
    if (!_changeController.isClosed) {
      _changeController.add(table);
    }
  }

  @override
  int get schemaVersion => 2;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await _createAllTables();
      await runV2UpgradeSafely();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await runV2UpgradeSafely();
      }
    },
  );

  Future<void> ensureInitialized() async {
    await customSelect('SELECT 1').get();
  }

  Future<void> _addColumnIfMissing(
    String table,
    String column,
    String definition,
  ) async {
    final info = await customSelect('PRAGMA table_info($table)').get();
    final exists = info.any((row) => row.read<String>('name') == column);
    if (!exists) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }

  /// Menjalankan migrasi non-destruktif ke skema v2 secara idempoten.
  Future<void> runV2UpgradeSafely() async {
    // 1. Kolom tambahan pada courses (dialects & downloadable module metadata)
    await _addColumnIfMissing(
      'courses',
      'dialect_id',
      "TEXT NOT NULL DEFAULT 'melayu_deli'",
    );
    await _addColumnIfMissing(
      'courses',
      'is_bundled',
      'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      'courses',
      'is_installed',
      'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      'courses',
      'installed_version',
      'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing('courses', 'download_url', 'TEXT');
    await _addColumnIfMissing('courses', 'sha256', 'TEXT');
    await _addColumnIfMissing(
      'courses',
      'size_bytes',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing('courses', 'color_identity_json', 'TEXT');
    await _addColumnIfMissing(
      'courses',
      'theme_key',
      "TEXT NOT NULL DEFAULT 'deli'",
    );
    await _addColumnIfMissing(
      'courses',
      'description',
      "TEXT NOT NULL DEFAULT ''",
    );

    // 2. Kolom tambahan pada words (provenance, fonologi, contoh kalimat, wilayah)
    await _addColumnIfMissing('words', 'pronunciation', 'TEXT');
    await _addColumnIfMissing('words', 'example_sentence', 'TEXT');
    await _addColumnIfMissing('words', 'example_translation', 'TEXT');
    await _addColumnIfMissing('words', 'usage_context', 'TEXT');
    await _addColumnIfMissing('words', 'region', 'TEXT');
    await _addColumnIfMissing('words', 'variants_json', 'TEXT');
    await _addColumnIfMissing(
      'words',
      'confidence',
      "TEXT NOT NULL DEFAULT 'high'",
    );
    await _addColumnIfMissing('words', 'sources_json', 'TEXT');

    // 3. Kolom tambahan pada phrases & sentences
    await _addColumnIfMissing('phrases', 'pronunciation', 'TEXT');
    await _addColumnIfMissing('phrases', 'region', 'TEXT');
    await _addColumnIfMissing(
      'phrases',
      'confidence',
      "TEXT NOT NULL DEFAULT 'high'",
    );
    await _addColumnIfMissing('phrases', 'sources_json', 'TEXT');

    await _addColumnIfMissing('sentences', 'region', 'TEXT');
    await _addColumnIfMissing(
      'sentences',
      'confidence',
      "TEXT NOT NULL DEFAULT 'high'",
    );
    await _addColumnIfMissing('sentences', 'sources_json', 'TEXT');

    // 4. Kolom metadata sinkronisasi pada tabel progres
    await _addColumnIfMissing('user_stats', 'created_at', 'TEXT');
    await _addColumnIfMissing(
      'user_stats',
      'is_synced',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing('user_stats', 'deleted_at', 'TEXT');
    await _addColumnIfMissing(
      'user_stats',
      'device_id',
      "TEXT NOT NULL DEFAULT 'local-device'",
    );
    await _addColumnIfMissing(
      'user_stats',
      'revision',
      'INTEGER NOT NULL DEFAULT 1',
    );

    await _addColumnIfMissing('course_progress', 'created_at', 'TEXT');
    await _addColumnIfMissing('course_progress', 'updated_at', 'TEXT');
    await _addColumnIfMissing(
      'course_progress',
      'is_synced',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing('course_progress', 'deleted_at', 'TEXT');
    await _addColumnIfMissing(
      'course_progress',
      'device_id',
      "TEXT NOT NULL DEFAULT 'local-device'",
    );
    await _addColumnIfMissing(
      'course_progress',
      'revision',
      'INTEGER NOT NULL DEFAULT 1',
    );

    await _addColumnIfMissing('word_mastery', 'created_at', 'TEXT');
    await _addColumnIfMissing('word_mastery', 'updated_at', 'TEXT');
    await _addColumnIfMissing(
      'word_mastery',
      'is_synced',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing('word_mastery', 'deleted_at', 'TEXT');
    await _addColumnIfMissing(
      'word_mastery',
      'device_id',
      "TEXT NOT NULL DEFAULT 'local-device'",
    );
    await _addColumnIfMissing(
      'word_mastery',
      'revision',
      'INTEGER NOT NULL DEFAULT 1',
    );

    await _addColumnIfMissing(
      'achievements_unlocked',
      'is_synced',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      'achievements_unlocked',
      'device_id',
      "TEXT NOT NULL DEFAULT 'local-device'",
    );

    // 5. Tabel baru schemaVersion 2
    await customStatement('''
      CREATE TABLE IF NOT EXISTS installed_modules (
        module_id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_bundled INTEGER NOT NULL DEFAULT 0,
        install_path TEXT,
        sha256 TEXT NOT NULL,
        size_bytes INTEGER NOT NULL DEFAULT 0,
        installed_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        word_count INTEGER NOT NULL DEFAULT 0,
        lesson_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await _addColumnIfMissing(
      'installed_modules',
      'word_count',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      'installed_modules',
      'lesson_count',
      'INTEGER NOT NULL DEFAULT 0',
    );

    await customStatement('''
      CREATE TABLE IF NOT EXISTS dialect_references (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        dialect_id TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        publication_year INTEGER,
        publisher TEXT,
        source_type TEXT NOT NULL,
        url TEXT,
        accessed_at TEXT,
        reliability TEXT NOT NULL DEFAULT 'high',
        supported_domain TEXT
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS xp_events (
        event_id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        source TEXT NOT NULL,
        device_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS streak_history (
        date TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        lessons_completed INTEGER NOT NULL DEFAULT 0,
        freeze_used INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL DEFAULT 'local-device',
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL UNIQUE,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        uid TEXT PRIMARY KEY NOT NULL,
        email TEXT,
        display_name TEXT,
        photo_url TEXT,
        is_anonymous INTEGER NOT NULL DEFAULT 1,
        device_id TEXT NOT NULL DEFAULT 'local-device',
        revision INTEGER NOT NULL DEFAULT 1,
        last_synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Index tambahan v2
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_words_course_category ON words(course_id, category)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_refs_course ON dialect_references(course_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_xp_events_synced ON xp_events(is_synced)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_retry ON sync_queue(retry_count, next_retry_at)',
    );
  }

  Future<void> _createAllTables() async {
    // 6.1 Tabel Konten (Read-only dari sisi aplikasi)
    await customStatement('''
      CREATE TABLE IF NOT EXISTS languages (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        tagline TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS courses (
        id TEXT PRIMARY KEY NOT NULL,
        language_id TEXT NOT NULL,
        dialect_id TEXT NOT NULL DEFAULT 'melayu_deli',
        name TEXT NOT NULL,
        region_label TEXT NOT NULL,
        status TEXT NOT NULL,
        accent_hex TEXT NOT NULL,
        content_version INTEGER NOT NULL DEFAULT 0,
        has_jawi INTEGER NOT NULL DEFAULT 0,
        is_bundled INTEGER NOT NULL DEFAULT 1,
        is_installed INTEGER NOT NULL DEFAULT 1,
        installed_version INTEGER NOT NULL DEFAULT 1,
        download_url TEXT,
        sha256 TEXT,
        size_bytes INTEGER NOT NULL DEFAULT 0,
        color_identity_json TEXT
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS words (
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
        pronunciation TEXT,
        example_sentence TEXT,
        example_translation TEXT,
        usage_context TEXT,
        region TEXT,
        variants_json TEXT,
        confidence TEXT NOT NULL DEFAULT 'high',
        sources_json TEXT,
        audio_path TEXT,
        image_path TEXT,
        validation_status TEXT NOT NULL DEFAULT 'draft',
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS phrases (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        deli TEXT NOT NULL,
        indonesia TEXT NOT NULL,
        jawi TEXT,
        level INTEGER NOT NULL DEFAULT 1,
        unit_id TEXT NOT NULL,
        audio_path TEXT,
        cultural_note TEXT,
        pronunciation TEXT,
        region TEXT,
        confidence TEXT NOT NULL DEFAULT 'high',
        sources_json TEXT,
        validation_status TEXT NOT NULL DEFAULT 'draft',
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS sentences (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        deli TEXT NOT NULL,
        indonesia TEXT NOT NULL,
        word_ids_json TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        region TEXT,
        confidence TEXT NOT NULL DEFAULT 'high',
        sources_json TEXT,
        validation_status TEXT NOT NULL DEFAULT 'draft',
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS dialogues (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        title TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        unit_id TEXT NOT NULL,
        validation_status TEXT NOT NULL DEFAULT 'draft',
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS dialogue_lines (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        dialogue_id TEXT NOT NULL,
        line_order INTEGER NOT NULL,
        speaker TEXT NOT NULL,
        deli TEXT NOT NULL,
        indonesia TEXT NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS letters (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        glyph TEXT NOT NULL,
        name TEXT NOT NULL,
        sound TEXT NOT NULL,
        example_word_jawi TEXT,
        example_word_latin TEXT,
        forms_json TEXT NOT NULL,
        connects_to_next INTEGER NOT NULL DEFAULT 1,
        validation_status TEXT NOT NULL DEFAULT 'draft',
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS articles (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body_markdown TEXT,
        sources_json TEXT NOT NULL,
        verification_notes TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        card_id TEXT,
        unlock_after_unit_id TEXT,
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS units (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        title TEXT NOT NULL,
        theme TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS lessons (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        unit_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        kind TEXT NOT NULL,
        xp_reward INTEGER NOT NULL DEFAULT 15,
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS lesson_items (
        course_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        PRIMARY KEY (lesson_id, item_id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS quiz_bank (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        lesson_id TEXT,
        exercise_type TEXT NOT NULL,
        prompt TEXT NOT NULL,
        options_json TEXT NOT NULL,
        correct_index INTEGER NOT NULL DEFAULT 0,
        pairs_json TEXT,
        correct_sentence TEXT,
        ref_item_id TEXT,
        topic TEXT NOT NULL,
        validation_status TEXT NOT NULL DEFAULT 'draft',
        needs_verification INTEGER NOT NULL DEFAULT 0,
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS collection_cards (
        id TEXT PRIMARY KEY NOT NULL,
        course_id TEXT NOT NULL,
        name TEXT NOT NULL,
        unlock_after_unit_id TEXT,
        fact TEXT,
        image_path TEXT,
        article_id TEXT,
        validation_status TEXT NOT NULL DEFAULT 'draft',
        deprecated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS content_meta (
        course_id TEXT PRIMARY KEY NOT NULL,
        content_version INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 6.2 Tabel Progres Pengguna
    await customStatement('''
      CREATE TABLE IF NOT EXISTS user_stats (
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
        created_at TEXT,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        device_id TEXT NOT NULL DEFAULT 'local-device',
        revision INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS course_progress (
        course_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        stars INTEGER NOT NULL DEFAULT 0,
        best_score INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        device_id TEXT NOT NULL DEFAULT 'local-device',
        revision INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (course_id, lesson_id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS word_mastery (
        course_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_type TEXT NOT NULL,
        strength INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 0,
        last_seen_at TEXT NOT NULL,
        next_review_at TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        device_id TEXT NOT NULL DEFAULT 'local-device',
        revision INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (course_id, item_id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS daily_quests (
        date TEXT NOT NULL,
        quest_id TEXT NOT NULL,
        progress INTEGER NOT NULL DEFAULT 0,
        target INTEGER NOT NULL DEFAULT 1,
        claimed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (date, quest_id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS achievements_unlocked (
        achievement_id TEXT PRIMARY KEY NOT NULL,
        unlocked_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL DEFAULT 'local-device'
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS collection_unlocked (
        course_id TEXT NOT NULL,
        card_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        PRIMARY KEY (course_id, card_id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS inventory (
        item_id TEXT PRIMARY KEY NOT NULL,
        qty INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS xp_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        course_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        source TEXT NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_type TEXT NOT NULL,
        reason TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Index performa (Bagian 9)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_words_course_level ON words(course_id, level)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_phrases_course_level ON phrases(course_id, level)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_mastery_course_item ON word_mastery(course_id, item_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_mastery_next_review ON word_mastery(next_review_at)',
    );

    final nowIso = DateTime.now().toIso8601String();
    await customStatement(
      '''
      INSERT OR IGNORE INTO user_stats (
        id, xp_total, level, coins, hearts, hearts_updated_at,
        streak_current, streak_best, last_active_date, streak_freezes,
        daily_goal_minutes, active_course_id, display_name, learning_goal,
        casual_mode, onboarding_completed, created_at, updated_at,
        is_synced, device_id, revision
      ) VALUES (1, 0, 1, 20, 5, ?, 0, 0, NULL, 1, 10, NULL, 'Pelajar', 'budaya', 0, 0, ?, ?, 0, 'local-device', 1)
      ''',
      [nowIso, nowIso, nowIso],
    );
  }

  @override
  Future<void> close() async {
    await _changeController.close();
    await super.close();
  }
}
