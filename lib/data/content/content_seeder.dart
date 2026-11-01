import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:katara/core/app_logger.dart';
import 'package:katara/data/db/app_database.dart';

typedef AssetStringLoader = Future<String> Function(String assetPath);

class ContentSeeder {
  ContentSeeder({
    required this.db,
    AssetStringLoader? loadAsset,
  }) : _loadAsset = loadAsset ?? rootBundle.loadString;

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
    final languages =
        (coursesJson['languages'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final courses =
        (coursesJson['courses'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();

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
          [
            lang['id'],
            lang['name'],
            lang['tagline'] ?? '',
            lang['order'] ?? 1,
          ],
        );
      }

      for (final c in courses) {
        await db.customStatement(
          '''
          INSERT INTO courses (
            id, language_id, name, region_label, status,
            accent_hex, content_version, has_jawi
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            language_id = excluded.language_id,
            name = excluded.name,
            region_label = excluded.region_label,
            status = excluded.status,
            accent_hex = excluded.accent_hex,
            content_version = excluded.content_version,
            has_jawi = excluded.has_jawi
          ''',
          [
            c['id'],
            c['language_id'],
            c['name'],
            c['region_label'] ?? '',
            c['status'] ?? 'coming_soon',
            c['accent_hex'] ?? '#F5B700',
            c['content_version'] ?? 0,
            (c['has_jawi'] == true) ? 1 : 0,
          ],
        );
      }
    });

    for (final c in courses) {
      final courseId = c['id'] as String;
      final status = c['status'] as String? ?? 'coming_soon';
      if (status != 'active') continue;

      final courseManifest =
          coursesManifest[courseId] as Map<String, dynamic>? ?? const {};
      final manifestVersion =
          (courseManifest['content_version'] as num?)?.toInt() ??
              (c['content_version'] as num?)?.toInt() ??
              1;
      final manifestChecksum =
          courseManifest['checksum'] as String? ?? 'v$manifestVersion';

      final existingMetaRows = await db.customSelect(
        'SELECT content_version, checksum FROM content_meta WHERE course_id = ?',
        variables: [Variable.withString(courseId)],
      ).get();

      if (!force && existingMetaRows.isNotEmpty) {
        final existingVersion =
            existingMetaRows.first.read<int>('content_version');
        if (manifestVersion <= existingVersion) {
          continue;
        }
      }

      await _seedCourseContent(
        courseId: courseId,
        version: manifestVersion,
        checksum: manifestChecksum,
      );
    }
  }

  Future<void> _seedCourseContent({
    required String courseId,
    required int version,
    required String checksum,
  }) async {
    final stopwatch = Stopwatch()..start();

    Future<List<Map<String, dynamic>>> loadList(String fileName) async {
      final raw = await _loadAsset('assets/content/$courseId/$fileName');
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
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

    await db.transaction(() async {
      // Tandai item course ini sebagai deprecated=1 terlebih dahulu;
      // item yang masih ada di versi baru akan di-set kembali ke deprecated=0 saat upsert.
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

      for (final w in words) {
        await db.customStatement(
          '''
          INSERT INTO words (
            id, course_id, deli, indonesia, jawi, category, level,
            unit_id, pos, register, raw_register, notes,
            audio_path, image_path, validation_status, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
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
            deprecated = 0
          ''',
          [
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
          ],
        );
      }

      for (final p in phrases) {
        await db.customStatement(
          '''
          INSERT INTO phrases (
            id, course_id, deli, indonesia, jawi, level,
            unit_id, audio_path, cultural_note, validation_status, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
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
            deprecated = 0
          ''',
          [
            p['id'],
            courseId,
            p['deli'],
            p['indonesia'],
            p['jawi'],
            p['level'] ?? 1,
            p['unit_id'] ?? '$courseId:u:0001',
            p['audio_path'],
            p['cultural_note'],
            p['validation_status'] ?? 'draft',
          ],
        );
      }

      for (final s in sentences) {
        await db.customStatement(
          '''
          INSERT INTO sentences (
            id, course_id, deli, indonesia, word_ids_json,
            level, validation_status, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 0)
          ON CONFLICT(id) DO UPDATE SET
            course_id = excluded.course_id,
            deli = excluded.deli,
            indonesia = excluded.indonesia,
            word_ids_json = excluded.word_ids_json,
            level = excluded.level,
            validation_status = excluded.validation_status,
            deprecated = 0
          ''',
          [
            s['id'],
            courseId,
            s['deli'],
            s['indonesia'],
            jsonEncode(s['word_ids'] ?? const <String>[]),
            s['level'] ?? 1,
            s['validation_status'] ?? 'draft',
          ],
        );
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
            d['validation_status'] ?? 'draft',
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
            l['glyph'],
            l['name'] ?? '',
            l['sound'] ?? '',
            l['example_word_jawi'],
            l['example_word_latin'],
            jsonEncode(l['forms'] ?? const <String, dynamic>{}),
            (l['connects_to_next'] == true) ? 1 : 0,
            l['validation_status'] ?? 'draft',
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
            a['body_markdown'],
            jsonEncode(a['sources'] ?? const <String>[]),
            a['verification_notes'],
            a['status'] ?? 'draft',
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
          for (var idx = 0; idx < refs.length; idx++) {
            await db.customStatement(
              '''
              INSERT OR REPLACE INTO lesson_items (
                course_id, lesson_id, item_id, sort_order
              ) VALUES (?, ?, ?, ?)
              ''',
              [courseId, lessonId, refs[idx].toString(), idx + 1],
            );
          }
        }
      }

      for (final q in quizBank) {
        await db.customStatement(
          '''
          INSERT INTO quiz_bank (
            id, course_id, lesson_id, exercise_type, prompt,
            options_json, correct_index, pairs_json, correct_sentence,
            ref_item_id, topic, validation_status, needs_verification, deprecated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
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
          ''',
          [
            q['id'],
            courseId,
            q['lesson_id'],
            q['exercise_type'] ?? 'mcq_translate',
            q['prompt'],
            jsonEncode(q['options'] ?? const <String>[]),
            q['correct_index'] ?? 0,
            q['pairs'] != null ? jsonEncode(q['pairs']) : null,
            q['correct_sentence'],
            q['ref_item_id'],
            q['topic'] ?? 'umum',
            q['validation_status'] ?? 'draft',
            (q['needs_verification'] == true) ? 1 : 0,
          ],
        );
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
            card['fact'],
            card['image_path'],
            card['article_id'],
            card['validation_status'] ?? 'draft',
          ],
        );
      }

      await db.customStatement(
        '''
        INSERT INTO content_meta (course_id, content_version, checksum, updated_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(course_id) DO UPDATE SET
          content_version = excluded.content_version,
          checksum = excluded.checksum,
          updated_at = excluded.updated_at
        ''',
        [courseId, version, checksum, DateTime.now().toIso8601String()],
      );
    });

    stopwatch.stop();
    AppLogger.info(
      'Seeding $courseId (v$version) selesai dalam ${stopwatch.elapsedMilliseconds} ms',
    );
  }
}
