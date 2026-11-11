import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:katara/core/app_logger.dart';
import 'package:katara/data/db/app_database.dart';

typedef AssetStringLoader = Future<String> Function(String assetPath);

Future<String> defaultAssetStringLoader(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return utf8.decode(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

class ContentSeeder {
  ContentSeeder({required this.db, AssetStringLoader? loadAsset})
    : _loadAsset = loadAsset ?? defaultAssetStringLoader;

  final AppDatabase db;
  final AssetStringLoader _loadAsset;

  Future<void> seedIfNeeded({bool force = false}) async {
    await db.ensureInitialized();

    final manifestStr = await _loadAsset('assets/content/manifest.json');
    final manifest = jsonDecode(manifestStr) as Map<String, dynamic>;
    final coursesManifest =
        (manifest['courses'] as Map<String, dynamic>? ?? const {});

    final coursesStr = await _loadAsset('assets/content/courses.json');
    final coursesJson = jsonDecode(coursesStr) as Map<String, dynamic>;
    final languages = (coursesJson['languages'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final courses = (coursesJson['courses'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    // Check which downloadable modules are already installed in SQLite so we don't overwrite their 'active' status
    final installedRows = await db
        .customSelect('SELECT course_id FROM installed_modules')
        .get();
    final installedCourseIds = installedRows
        .map((r) => r.read<String>('course_id'))
        .toSet();

    await db.transaction(() async {
      for (final lang in languages) {
        await db.customStatement(
          '''
          INSERT INTO languages (id, name, tagline, sort_order)
          VALUES (?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            tagline = excluded.tagline,
            sort_order = excluded.sort_order
          ''',
          [lang['id'], lang['name'], lang['tagline'] ?? '', lang['order'] ?? 1],
        );
      }

      final validCourseIds = courses
          .map((c) => c['id'] as String?)
          .whereType<String>()
          .toList();
      if (validCourseIds.isNotEmpty) {
        final placeholders = List.filled(validCourseIds.length, '?').join(', ');
        await db.customStatement(
          'DELETE FROM courses WHERE id NOT IN ($placeholders)',
          validCourseIds,
        );
      }

      for (final c in courses) {
        final cid = c['id'] as String;
        final isBundled = c['is_bundled'] != false;
        final defaultStatus = c['status'] as String? ?? 'coming_soon';
        final effectiveStatus = (!isBundled && installedCourseIds.contains(cid))
            ? 'active'
            : defaultStatus;

        await db.customStatement(
          '''
          INSERT INTO courses (
            id, language_id, name, region_label, status,
            accent_hex, content_version, has_jawi,
            is_bundled, size_bytes, sha256, download_url, theme_key, description
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            language_id = excluded.language_id,
            name = excluded.name,
            region_label = excluded.region_label,
            status = excluded.status,
            accent_hex = excluded.accent_hex,
            content_version = excluded.content_version,
            has_jawi = excluded.has_jawi,
            is_bundled = excluded.is_bundled,
            size_bytes = excluded.size_bytes,
            sha256 = excluded.sha256,
            download_url = excluded.download_url,
            theme_key = excluded.theme_key,
            description = excluded.description
          ''',
          [
            cid,
            c['language_id'],
            c['name'],
            c['region_label'] ?? '',
            effectiveStatus,
            c['accent_hex'] ?? '#F5B700',
            c['content_version'] ?? 0,
            (c['has_jawi'] == true) ? 1 : 0,
            isBundled ? 1 : 0,
            (c['size_bytes'] as num?)?.toInt() ?? 0,
            c['sha256'],
            c['download_url'],
            c['theme_key'] ?? 'deli',
            c['description'] ?? '',
          ],
        );
      }
    });

    for (final c in courses) {
      final courseId = c['id'] as String;
      final isBundled = c['is_bundled'] != false;
      final status = c['status'] as String? ?? 'coming_soon';
      if (!isBundled || status != 'active') continue;

      final courseManifest =
          coursesManifest[courseId] as Map<String, dynamic>? ?? const {};
      final manifestVersion =
          (courseManifest['content_version'] as num?)?.toInt() ??
          (c['content_version'] as num?)?.toInt() ??
          1;
      final manifestChecksum =
          courseManifest['checksum'] as String? ?? 'v$manifestVersion';

      final existingMetaRows = await db
          .customSelect(
            'SELECT content_version, checksum FROM content_meta WHERE course_id = ?',
            variables: [Variable.withString(courseId)],
          )
          .get();

      if (!force && existingMetaRows.isNotEmpty) {
        final existingVersion = existingMetaRows.first.read<int>(
          'content_version',
        );
        final existingChecksum = existingMetaRows.first.read<String>(
          'checksum',
        );
        if (manifestVersion <= existingVersion &&
            existingChecksum == manifestChecksum) {
          continue;
        }
      }

      await _seedCourseFromLoader(
        courseId: courseId,
        version: manifestVersion,
        checksum: manifestChecksum,
        isBundled: true,
        sizeBytes: 0,
        installPath: 'assets/content/$courseId',
        loadFile: (fileName) =>
            _loadAsset('assets/content/$courseId/$fileName'),
      );
    }
  }

  /// Seed a downloadable dialect module from an extracted local directory.
  Future<int> seedCourseFromDirectory({
    required String courseId,
    required Directory directory,
    required int sizeBytes,
    required String sha256Hash,
    String version = '1.1.0',
  }) async {
    if (courseId == 'ms-deli') {
      throw const FormatException(
        'Keamanan: Modul bawaan ms-deli tidak boleh ditimpa dari direktori eksternal.',
      );
    }
    if (!RegExp(r'^ms-[a-z0-9-]+$').hasMatch(courseId)) {
      throw FormatException('ID kursus modul tidak valid: $courseId');
    }

    await db.ensureInitialized();

    Future<String> loadFromDir(String fileName) async {
      final file = File('${directory.path}/$fileName');
      if (!file.existsSync()) {
        return '[]';
      }
      final content = file.readAsStringSync();
      // Validasi bahwa tidak ada entri yang mencoba menyuntikkan ID milik ms-deli atau kursus lain
      final decoded = jsonDecode(content);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final itemCourse = item['course_id'] as String?;
            final itemId = item['id'] as String? ?? '';
            if (itemCourse != null && itemCourse != courseId) {
              throw FormatException(
                'Pelanggaran isolasi kursus pada $fileName: ditemukan course_id "$itemCourse" di dalam paket "$courseId".',
              );
            }
            if (itemId.startsWith('ms-deli:')) {
              throw FormatException(
                'Pelanggaran isolasi ID pada $fileName: ID "$itemId" mencoba menimpa namespace ms-deli.',
              );
            }
          }
        }
      }
      return content;
    }

    int contentVersion = 1;
    final manifestFile = File('${directory.path}/manifest.json');
    if (manifestFile.existsSync()) {
      final m =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      contentVersion = (m['content_version'] as num?)?.toInt() ?? 1;
    }

    final wordCount = await _seedCourseFromLoader(
      courseId: courseId,
      version: contentVersion,
      checksum: sha256Hash,
      isBundled: false,
      sizeBytes: sizeBytes,
      installPath: directory.path,
      versionLabel: version,
      loadFile: loadFromDir,
    );

    await db.customStatement(
      "UPDATE courses SET status = 'active' WHERE id = ?",
      [courseId],
    );
    db.notifyTableChanged('courses');
    db.notifyTableChanged('installed_modules');
    return wordCount;
  }

  /// Uninstall a downloadable module's content rows while preserving user progress & XP.
  Future<void> uninstallCourseContent(String courseId) async {
    await db.ensureInitialized();
    await db.transaction(() async {
      for (final table in const [
        'words',
        'phrases',
        'sentences',
        'dialogue_lines',
        'dialogues',
        'letters',
        'articles',
        'lesson_items',
        'lessons',
        'units',
        'quiz_bank',
        'collection_cards',
        'dialect_references',
        'content_meta',
        'installed_modules',
      ]) {
        await db.customStatement('DELETE FROM $table WHERE course_id = ?', [
          courseId,
        ]);
      }

      await db.customStatement(
        "UPDATE courses SET status = 'downloadable' WHERE id = ? AND is_bundled = 0",
        [courseId],
      );
    });
    db.notifyTableChanged('courses');
    db.notifyTableChanged('installed_modules');
  }

  Future<int> _seedCourseFromLoader({
    required String courseId,
    required int version,
    required String checksum,
    required bool isBundled,
    required int sizeBytes,
    required String installPath,
    required Future<String> Function(String fileName) loadFile,
    String versionLabel = '1.1.0',
  }) async {
    final stopwatch = Stopwatch()..start();

    Future<List<Map<String, dynamic>>> loadList(String fileName) async {
      try {
        final raw = await loadFile(fileName);
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.cast<Map<String, dynamic>>();
      } catch (_) {
        return const <Map<String, dynamic>>[];
      }
    }

    final words = await loadList('words.json');
    final phrases = await loadList('phrases.json');
    final sentences = await loadList('sentences.json');
    final dialogues = await loadList('dialogues.json');
    final letters = await loadList('letters.json');
    final articles = await loadList('articles.json');
    final units = await loadList('units.json');
    final quizBank = await loadList('quiz_bank.json');
    final cards = await loadList('collection_cards.json');
    final references = await loadList('references.json');

    var lessonCount = 0;

    await db.transaction(() async {
      for (final table in const [
        'words',
        'phrases',
        'sentences',
        'dialogues',
        'letters',
        'articles',
        'units',
        'lessons',
        'quiz_bank',
        'collection_cards',
      ]) {
        await db.customStatement(
          'UPDATE $table SET deprecated = 1 WHERE course_id = ?',
          [courseId],
        );
      }

      for (var i = 0; i < words.length; i += 25) {
        final chunk = words.skip(i).take(25).toList();
        final placeholders = List.filled(
          chunk.length,
          '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?)',
        ).join(', ');
        final args = <Object?>[];
        for (final w in chunk) {
          args.addAll([
            w['id'],
            courseId,
            w['deli'],
            w['indonesia'],
            w['jawi'],
            w['category'] ?? 'umum',
            w['level'] ?? 1,
            w['unit_id'] ?? '$courseId:u:0001',
            w['pos'] ?? 'benda',
            w['register'] ?? 'deli',
            w['raw_register'] ?? 'deli',
            w['notes'],
            w['audio_path'],
            w['image_path'],
            w['validation_status'] ?? 'draft',
            w['pronunciation'],
            w['example_sentence'],
            w['example_translation'],
            w['region'],
            jsonEncode(w['variants'] ?? const <String>[]),
            w['confidence'] ?? 'high',
            jsonEncode(w['sources'] ?? const <String>[]),
          ]);
        }
        await db.customStatement('''
          INSERT INTO words (
            id, course_id, deli, indonesia, jawi, category, level,
            unit_id, pos, register, raw_register, notes,
            audio_path, image_path, validation_status, deprecated,
            pronunciation, example_sentence, example_translation,
            region, variants_json, confidence, sources_json
          ) VALUES $placeholders
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            deli = excluded.deli,
            indonesia = excluded.indonesia,
            jawi = excluded.jawi,
            category = excluded.category,
            level = excluded.level,
            unit_id = excluded.unit_id,
            pos = excluded.pos,
            register = excluded.register,
            raw_register = excluded.raw_register,
            notes = excluded.notes,
            audio_path = excluded.audio_path,
            image_path = excluded.image_path,
            validation_status = excluded.validation_status,
            deprecated = 0,
            pronunciation = excluded.pronunciation,
            example_sentence = excluded.example_sentence,
            example_translation = excluded.example_translation,
            region = excluded.region,
            variants_json = excluded.variants_json,
            confidence = excluded.confidence,
            sources_json = excluded.sources_json
          ''', args);
      }

      for (var i = 0; i < phrases.length; i += 25) {
        final chunk = phrases.skip(i).take(25).toList();
        final placeholders = List.filled(
          chunk.length,
          '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?)',
        ).join(', ');
        final args = <Object?>[];
        for (final p in chunk) {
          args.addAll([
            p['id'],
            courseId,
            p['deli'],
            p['indonesia'],
            p['jawi'],
            p['level'] ?? 1,
            p['unit_id'] ?? '$courseId:u:0001',
            p['audio_path'],
            p['cultural_note'] ?? p['notes'],
            p['validation_status'] ?? 'draft',
            p['pronunciation'],
            p['region'],
            p['confidence'] ?? 'high',
            jsonEncode(p['sources'] ?? const <String>[]),
          ]);
        }
        await db.customStatement('''
          INSERT INTO phrases (
            id, course_id, deli, indonesia, jawi, level,
            unit_id, audio_path, cultural_note, validation_status, deprecated,
            pronunciation, region, confidence, sources_json
          ) VALUES $placeholders
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            deli = excluded.deli,
            indonesia = excluded.indonesia,
            jawi = excluded.jawi,
            level = excluded.level,
            unit_id = excluded.unit_id,
            audio_path = excluded.audio_path,
            cultural_note = excluded.cultural_note,
            validation_status = excluded.validation_status,
            deprecated = 0,
            pronunciation = excluded.pronunciation,
            region = excluded.region,
            confidence = excluded.confidence,
            sources_json = excluded.sources_json
          ''', args);
      }

      for (var i = 0; i < sentences.length; i += 25) {
        final chunk = sentences.skip(i).take(25).toList();
        final placeholders = List.filled(
          chunk.length,
          '(?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)',
        ).join(', ');
        final args = <Object?>[];
        for (final s in chunk) {
          args.addAll([
            s['id'],
            courseId,
            s['deli'],
            s['indonesia'],
            jsonEncode(s['word_ids'] ?? const <String>[]),
            s['level'] ?? 1,
            s['validation_status'] ?? 'draft',
            s['region'],
            s['confidence'] ?? 'high',
            jsonEncode(s['sources'] ?? const <String>[]),
          ]);
        }
        await db.customStatement('''
          INSERT INTO sentences (
            id, course_id, deli, indonesia, word_ids_json,
            level, validation_status, deprecated,
            region, confidence, sources_json
          ) VALUES $placeholders
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            deli = excluded.deli,
            indonesia = excluded.indonesia,
            word_ids_json = excluded.word_ids_json,
            level = excluded.level,
            validation_status = excluded.validation_status,
            deprecated = 0,
            region = excluded.region,
            confidence = excluded.confidence,
            sources_json = excluded.sources_json
          ''', args);
      }

      for (final d in dialogues) {
        final did = d['id'] as String;
        await db.customStatement(
          '''
          INSERT INTO dialogues (
            id, course_id, title, level, unit_id, validation_status, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, 0)
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            title = excluded.title,
            level = excluded.level,
            unit_id = excluded.unit_id,
            validation_status = excluded.validation_status,
            deprecated = 0
          ''',
          [
            did,
            courseId,
            d['title'] ?? '',
            d['level'] ?? 1,
            d['unit_id'] ?? '$courseId:u:0001',
            d['validation_status'] ?? 'speaker_checked',
          ],
        );

        await db.customStatement(
          'DELETE FROM dialogue_lines WHERE dialogue_id = ?',
          [did],
        );
        final lines = (d['lines'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final order = line['order'] ?? (i + 1);
          await db.customStatement(
            '''
            INSERT INTO dialogue_lines (
              id, course_id, dialogue_id, line_order, speaker, deli, indonesia
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              '$did:line:$order',
              courseId,
              did,
              order,
              line['speaker'] ?? 'Penutur',
              line['deli'] ?? '',
              line['indonesia'] ?? '',
            ],
          );
        }
      }

      for (final l in letters) {
        await db.customStatement(
          '''
          INSERT INTO letters (
            id, course_id, glyph, name, sound, example_word_jawi,
            example_word_latin, forms_json, connects_to_next, validation_status, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            glyph = excluded.glyph,
            name = excluded.name,
            sound = excluded.sound,
            example_word_jawi = excluded.example_word_jawi,
            example_word_latin = excluded.example_word_latin,
            forms_json = excluded.forms_json,
            connects_to_next = excluded.connects_to_next,
            validation_status = excluded.validation_status,
            deprecated = 0
          ''',
          [
            l['id'],
            courseId,
            l['glyph'] ?? l['arabic_char'] ?? 'ا',
            l['name'] ?? '',
            l['sound'] ?? l['latin_equiv'] ?? '',
            l['example_word_jawi'] ?? l['example_jawi'],
            l['example_word_latin'] ?? l['example_deli'],
            jsonEncode(l['forms'] ?? const <String, dynamic>{}),
            (l['connects_to_next'] == true) ? 1 : 0,
            l['validation_status'] ?? 'speaker_checked',
          ],
        );
      }

      for (final a in articles) {
        await db.customStatement(
          '''
          INSERT INTO articles (
            id, course_id, title, body_markdown, sources_json,
            verification_notes, status, card_id, unlock_after_unit_id, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            title = excluded.title,
            body_markdown = excluded.body_markdown,
            sources_json = excluded.sources_json,
            verification_notes = excluded.verification_notes,
            status = excluded.status,
            card_id = excluded.card_id,
            unlock_after_unit_id = excluded.unlock_after_unit_id,
            deprecated = 0
          ''',
          [
            a['id'],
            courseId,
            a['title'],
            a['body_markdown'] ?? a['summary'] ?? '',
            jsonEncode(a['sources'] ?? const <String>[]),
            a['verification_notes'],
            a['status'] ?? 'speaker_checked',
            a['card_id'],
            a['unlock_after_unit_id'],
          ],
        );
      }

      for (final u in units) {
        final unitId = u['id'] as String;
        await db.customStatement(
          '''
          INSERT INTO units (
            id, course_id, title, theme, sort_order, level, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, 0)
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            title = excluded.title,
            theme = excluded.theme,
            sort_order = excluded.sort_order,
            level = excluded.level,
            deprecated = 0
          ''',
          [
            unitId,
            courseId,
            u['title'],
            u['theme'] ?? 'umum',
            u['order'] ?? 1,
            u['level'] ?? 1,
          ],
        );

        final lessons = (u['lessons'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        lessonCount += lessons.length;
        for (final les in lessons) {
          final lessonId = les['id'] as String;
          await db.customStatement(
            '''
            INSERT INTO lessons (
              id, course_id, unit_id, sort_order, kind, xp_reward, deprecated
            ) VALUES (?, ?, ?, ?, ?, ?, 0)
            ON CONFLICT(id) DO UPDATE SET
              course_id = excluded.course_id,
              unit_id = excluded.unit_id,
              sort_order = excluded.sort_order,
              kind = excluded.kind,
              xp_reward = excluded.xp_reward,
              deprecated = 0
            ''',
            [
              lessonId,
              courseId,
              unitId,
              les['order'] ?? 1,
              les['kind'] ?? 'vocab',
              les['xp_reward'] ?? 15,
            ],
          );

          await db.customStatement(
            'DELETE FROM lesson_items WHERE lesson_id = ?',
            [lessonId],
          );
          final refs = (les['item_refs'] as List<dynamic>? ?? const []);
          if (refs.isNotEmpty) {
            final placeholders = List.filled(
              refs.length,
              '(?, ?, ?, ?)',
            ).join(', ');
            final args = <Object?>[];
            for (var idx = 0; idx < refs.length; idx++) {
              args.addAll([courseId, lessonId, refs[idx].toString(), idx + 1]);
            }
            await db.customStatement('''
              INSERT OR REPLACE INTO lesson_items (
                course_id, lesson_id, item_id, sort_order
              ) VALUES $placeholders
              ''', args);
          }
        }
      }

      for (var i = 0; i < quizBank.length; i += 25) {
        final chunk = quizBank.skip(i).take(25).toList();
        final placeholders = List.filled(
          chunk.length,
          '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)',
        ).join(', ');
        final args = <Object?>[];
        for (final q in chunk) {
          args.addAll([
            q['id'],
            courseId,
            q['lesson_id'],
            q['exercise_type'] ?? 'mcq_word',
            q['prompt'],
            jsonEncode(q['options'] ?? const <String>[]),
            q['correct_index'] ?? 0,
            q['pairs'] != null ? jsonEncode(q['pairs']) : null,
            q['correct_sentence'],
            q['ref_item_id'],
            q['topic'] ?? 'umum',
            q['validation_status'] ?? 'speaker_checked',
            (q['needs_verification'] == true) ? 1 : 0,
          ]);
        }
        await db.customStatement('''
          INSERT INTO quiz_bank (
            id, course_id, lesson_id, exercise_type, prompt,
            options_json, correct_index, pairs_json, correct_sentence,
            ref_item_id, topic, validation_status, needs_verification, deprecated
          ) VALUES $placeholders
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            lesson_id = excluded.lesson_id,
            exercise_type = excluded.exercise_type,
            prompt = excluded.prompt,
            options_json = excluded.options_json,
            correct_index = excluded.correct_index,
            pairs_json = excluded.pairs_json,
            correct_sentence = excluded.correct_sentence,
            ref_item_id = excluded.ref_item_id,
            topic = excluded.topic,
            validation_status = excluded.validation_status,
            needs_verification = excluded.needs_verification,
            deprecated = 0
          ''', args);
      }

      for (final card in cards) {
        await db.customStatement(
          '''
          INSERT INTO collection_cards (
            id, course_id, name, unlock_after_unit_id, fact,
            image_path, article_id, validation_status, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            name = excluded.name,
            unlock_after_unit_id = excluded.unlock_after_unit_id,
            fact = excluded.fact,
            image_path = excluded.image_path,
            article_id = excluded.article_id,
            validation_status = excluded.validation_status,
            deprecated = 0
          ''',
          [
            card['id'],
            courseId,
            card['name'],
            card['unlock_after_unit_id'],
            card['fact'] ?? card['description'] ?? '',
            card['image_path'],
            card['article_id'],
            card['validation_status'] ?? 'speaker_checked',
          ],
        );
      }

      // Seed dialect_references
      await db.customStatement(
        'DELETE FROM dialect_references WHERE course_id = ?',
        [courseId],
      );
      final dialectId = switch (courseId) {
        'ms-langkat' => 'melayu_langkat',
        'ms-palembang' => 'melayu_palembang',
        _ => 'melayu_deli',
      };
      for (final ref in references) {
        final refId = (ref['id'] ?? ref['source_id']).toString();
        await db.customStatement(
          '''
          INSERT OR REPLACE INTO dialect_references (
            id, course_id, dialect_id, title, author, publication_year,
            publisher, source_type, url, accessed_at, reliability, supported_domain
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            '$courseId:$refId',
            courseId,
            dialectId,
            ref['title'] ?? '',
            ref['author'] ?? '',
            (ref['publication_year'] as num?)?.toInt() ?? 2020,
            ref['publisher'] ?? '',
            ref['source_type'] ?? 'reference',
            ref['url'] ?? '',
            ref['access_date'] ?? '2026-11-11',
            ref['reliability'] ?? 'high',
            ref['notes'] ?? '',
          ],
        );
      }

      final nowIso = DateTime.now().toIso8601String();
      await db.customStatement(
        '''
        INSERT INTO content_meta (course_id, content_version, checksum, updated_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(course_id) DO UPDATE SET
          content_version = excluded.content_version,
          checksum = excluded.checksum,
          updated_at = excluded.updated_at
        ''',
        [courseId, version, checksum, nowIso],
      );

      await db.customStatement(
        '''
        INSERT INTO installed_modules (
          module_id, course_id, version, is_bundled, install_path,
          sha256, size_bytes, installed_at, updated_at, word_count, lesson_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(module_id) DO UPDATE SET
          course_id = excluded.course_id,
          version = excluded.version,
          is_bundled = excluded.is_bundled,
          install_path = excluded.install_path,
          sha256 = excluded.sha256,
          size_bytes = excluded.size_bytes,
          installed_at = excluded.installed_at,
          updated_at = excluded.updated_at,
          word_count = excluded.word_count,
          lesson_count = excluded.lesson_count
        ''',
        [
          courseId,
          courseId,
          version,
          isBundled ? 1 : 0,
          installPath,
          checksum,
          sizeBytes,
          nowIso,
          nowIso,
          words.length,
          lessonCount,
        ],
      );
    });

    stopwatch.stop();
    AppLogger.info(
      'Seeding $courseId (v$version) selesai dalam ${stopwatch.elapsedMilliseconds} ms',
    );
    return words.length;
  }
}
