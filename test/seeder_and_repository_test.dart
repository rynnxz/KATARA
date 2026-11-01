import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/data/repositories/local_content_repository.dart';
import 'package:katara/data/repositories/local_progress_repository.dart';
import 'package:katara/domain/entities/user_progress.dart';

void main() {
  Future<String> diskAssetLoader(String assetPath) async {
    return File(assetPath).readAsString();
  }

  group('ContentSeeder & Local Repositories (Fase 2)', () {
    late AppDatabase db;
    late ContentSeeder seeder;
    late LocalContentRepository contentRepo;
    late LocalProgressRepository progressRepo;

    setUp(() {
      db = AppDatabase.memory();
      seeder = ContentSeeder(db: db, loadAsset: diskAssetLoader);
      contentRepo = LocalContentRepository(db: db, loadAsset: diskAssetLoader);
      progressRepo = LocalProgressRepository(
        db: db,
        contentRepository: contentRepo,
        clock: () => DateTime(2026, 11, 1, 10, 0),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('ContentSeeder seeds Melayu Deli in < 2 seconds and is idempotent on second run', () async {
      final sw = Stopwatch()..start();
      await seeder.seedIfNeeded();
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(2000));

      final courses = await contentRepo.getCourses();
      expect(courses.length, 2);
      expect(courses.first.id, 'ms-deli');
      expect(courses.first.isActive, isTrue);

      final words = await contentRepo.getWords('ms-deli');
      final phrases = await contentRepo.getPhrases('ms-deli');
      final sentences = await contentRepo.getSentences('ms-deli');
      final dialogues = await contentRepo.getDialogues('ms-deli');
      final letters = await contentRepo.getLetters('ms-deli');
      final units = await contentRepo.getUnits('ms-deli');
      final quizBank = await contentRepo.getQuizBank('ms-deli');
      final cards = await contentRepo.getCollectionCards('ms-deli');

      expect(words.length, 67);
      expect(phrases.length, 10);
      expect(sentences.length, 10);
      expect(dialogues.length, 2);
      expect(letters.length, 6);
      expect(units.length, 10);
      expect(quizBank.length, 62);
      expect(cards.length, 5);

      // Seed kedua kali (termasuk dengan force=true) tidak boleh menggandakan baris.
      await seeder.seedIfNeeded();
      await seeder.seedIfNeeded(force: true);

      final wordsAfter = await contentRepo.getWords('ms-deli');
      final phrasesAfter = await contentRepo.getPhrases('ms-deli');
      expect(wordsAfter.length, 67);
      expect(phrasesAfter.length, 10);
    });

    test('Content version upgrade upserts content, marks removed items deprecated, and preserves user progress', () async {
      await seeder.seedIfNeeded();

      // Simulasikan pengguna menyelesaikan 1 pelajaran.
      final units = await contentRepo.getUnits('ms-deli');
      final firstUnit = units.first;
      final firstLesson = firstUnit.lessons.first;

      final result = await progressRepo.completeLesson(
        LessonAttempt(
          courseId: 'ms-deli',
          lessonId: firstLesson.id,
          unitId: firstUnit.id,
          lessonKind: firstLesson.kind,
          totalQuestions: 6,
          correctFirstTryCount: 6,
          wrongCount: 0,
          maxCombo: 6,
          itemOutcomes: const [
            ItemAttemptOutcome(
              itemId: 'ms-deli:w:0001',
              itemType: 'word',
              isCorrect: true,
            ),
          ],
        ),
      );

      expect(result.xpEarned, greaterThan(0));
      expect(result.starsEarned, 3);

      // Simulasikan manifest v2 di mana kata pertama diperbarui dan kata terakhir dihapus dari daftar.
      final customSeeder = ContentSeeder(
        db: db,
        loadAsset: (path) async {
          final original = await diskAssetLoader(path);
          if (path == 'assets/content/manifest.json') {
            final map = jsonDecode(original) as Map<String, dynamic>;
            (map['courses'] as Map<String, dynamic>)['ms-deli']['content_version'] = 2;
            return jsonEncode(map);
          }
          if (path == 'assets/content/ms-deli/words.json') {
            final list = (jsonDecode(original) as List<dynamic>)
                .cast<Map<String, dynamic>>();
            list.first['indonesia'] = 'kabar / berita';
            list.removeLast(); // Hapus 1 kata untuk menguji penandaan deprecated
            return jsonEncode(list);
          }
          return original;
        },
      );

      await customSeeder.seedIfNeeded();

      // Pastikan progres tetap utuh setelah update konten v2.
      final stats = await progressRepo.getStats();
      expect(stats.xpTotal, result.xpEarned);
      expect(stats.streakCurrent, 1);

      final courseProg = await progressRepo.getCourseProgress('ms-deli');
      expect(courseProg[firstLesson.id]?.stars, 3);

      final mastery = await progressRepo.getCourseMastery('ms-deli');
      expect(mastery.any((m) => m.itemId == 'ms-deli:w:0001' && m.strength == 1), isTrue);

      // Kata aktif berkurang 1 (jadi 66), kata pertama ter-update, dan kata yang dihapus ditandai deprecated=1 di DB.
      final activeWords = await contentRepo.getWords('ms-deli');
      expect(activeWords.length, 66);
      expect(activeWords.first.indonesia, 'kabar / berita');

      final deprecatedRow = await db
          .customSelect('SELECT COUNT(*) AS cnt FROM words WHERE deprecated = 1')
          .getSingle();
      expect(deprecatedRow.read<int>('cnt'), 1);
    });
  });
}
