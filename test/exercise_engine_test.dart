import 'package:flutter_test/flutter_test.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/engine/answer_normalizer.dart';
import 'package:katara/engine/exercise_generator.dart';
import 'package:katara/engine/exercise_models.dart';
import 'package:katara/engine/lesson_session_engine.dart';

void main() {
  group('AnswerNormalizer (Bagian 13.2)', () {
    test('normalizes case, multiple spaces, and trailing punctuation', () {
      expect(
        AnswerNormalizer.normalize('  Nak   ke MANE, bang?!  '),
        'nak ke mane, bang',
      );
      expect(
        AnswerNormalizer.isMatch('Terime kasih.', '  terime   kasih '),
        isTrue,
      );
    });
  });

  group('ExerciseGenerator & LessonSessionEngine (Bagian 13)', () {
    final sampleWords = <WordModel>[
      const WordModel(
        id: 'ms-deli:w:0001',
        courseId: 'ms-deli',
        deli: 'kabar',
        indonesia: 'kabar',
        category: 'sapaan',
        level: 1,
        unitId: 'ms-deli:u:0001',
        pos: 'benda',
        register: 'deli',
        rawRegister: 'deli',
        validationStatus: 'draft',
      ),
      const WordModel(
        id: 'ms-deli:w:0002',
        courseId: 'ms-deli',
        deli: 'jemput',
        indonesia: 'silakan / mengundang',
        category: 'sapaan',
        level: 1,
        unitId: 'ms-deli:u:0001',
        pos: 'kerja',
        register: 'deli',
        rawRegister: 'deli',
        validationStatus: 'draft',
      ),
      const WordModel(
        id: 'ms-deli:w:0003',
        courseId: 'ms-deli',
        deli: 'masuk',
        indonesia: 'masuk',
        category: 'sapaan',
        level: 1,
        unitId: 'ms-deli:u:0001',
        pos: 'kerja',
        register: 'deli',
        rawRegister: 'deli',
        validationStatus: 'draft',
      ),
      const WordModel(
        id: 'ms-deli:w:0004',
        courseId: 'ms-deli',
        deli: 'terime',
        indonesia: 'terima',
        category: 'sapaan',
        level: 1,
        unitId: 'ms-deli:u:0001',
        pos: 'kerja',
        register: 'deli',
        rawRegister: 'deli',
        validationStatus: 'draft',
      ),
      const WordModel(
        id: 'ms-deli:w:0005',
        courseId: 'ms-deli',
        deli: 'kasih',
        indonesia: 'kasih',
        category: 'sapaan',
        level: 1,
        unitId: 'ms-deli:u:0001',
        pos: 'benda',
        register: 'deli',
        rawRegister: 'deli',
        validationStatus: 'draft',
      ),
      const WordModel(
        id: 'ms-deli:w:0006',
        courseId: 'ms-deli',
        deli: 'maaf',
        indonesia: 'maaf',
        category: 'sapaan',
        level: 1,
        unitId: 'ms-deli:u:0001',
        pos: 'benda',
        register: 'deli',
        rawRegister: 'deli',
        validationStatus: 'draft',
      ),
    ];

    final samplePhrases = <PhraseModel>[
      const PhraseModel(
        id: 'ms-deli:p:0001',
        courseId: 'ms-deli',
        deli: 'Ape kabar?',
        indonesia: 'Apa kabar?',
        level: 1,
        unitId: 'ms-deli:u:0001',
        validationStatus: 'draft',
      ),
      const PhraseModel(
        id: 'ms-deli:p:0002',
        courseId: 'ms-deli',
        deli: 'Jemput masuk.',
        indonesia: 'Silakan masuk.',
        level: 1,
        unitId: 'ms-deli:u:0001',
        validationStatus: 'draft',
      ),
    ];

    final sampleSentences = <SentenceModel>[
      const SentenceModel(
        id: 'ms-deli:s:0001',
        courseId: 'ms-deli',
        deli: 'Jemput masuk, tengku.',
        indonesia: 'Silakan masuk, tengku.',
        wordIds: ['ms-deli:w:0002', 'ms-deli:w:0003'],
        level: 1,
        validationStatus: 'draft',
      ),
    ];

    final sampleLetters = <JawiLetterModel>[
      const JawiLetterModel(
        id: 'ms-deli:j:0001',
        courseId: 'ms-deli',
        glyph: 'چ',
        name: 'ca',
        sound: 'c',
        forms: {'isolated': 'چ'},
        connectsToNext: true,
        validationStatus: 'draft',
        exampleWordLatin: 'cakap',
      ),
      const JawiLetterModel(
        id: 'ms-deli:j:0002',
        courseId: 'ms-deli',
        glyph: 'ڠ',
        name: 'nga',
        sound: 'ng',
        forms: {'isolated': 'ڠ'},
        connectsToNext: true,
        validationStatus: 'draft',
        exampleWordLatin: 'bunga',
      ),
      const JawiLetterModel(
        id: 'ms-deli:j:0003',
        courseId: 'ms-deli',
        glyph: 'ڤ',
        name: 'pa',
        sound: 'p',
        forms: {'isolated': 'ڤ'},
        connectsToNext: true,
        validationStatus: 'draft',
        exampleWordLatin: 'pinggan',
      ),
      const JawiLetterModel(
        id: 'ms-deli:j:0004',
        courseId: 'ms-deli',
        glyph: 'ݢ',
        name: 'ga',
        sound: 'g',
        forms: {'isolated': 'ݢ'},
        connectsToNext: true,
        validationStatus: 'draft',
        exampleWordLatin: 'gulai',
      ),
    ];

    final lesson = LessonModel(
      id: 'ms-deli:l:0001',
      courseId: 'ms-deli',
      unitId: 'ms-deli:u:0001',
      order: 1,
      kind: 'vocab',
      itemRefs: sampleWords.map((w) => w.id).toList(),
      xpReward: 15,
    );

    test('is deterministic with same seed, generates >= 4 exercise types, max 2 consecutive identical types, and filters audio/unverified', () {
      const generator = ExerciseGenerator();
      final quizWithUnverified = <QuizBankItemModel>[
        const QuizBankItemModel(
          id: 'ms-deli:q:9999',
          courseId: 'ms-deli',
          lessonId: 'ms-deli:l:0001',
          exerciseType: 'mcq_translate',
          prompt: 'Tahun berdiri Istana Maimun [verifikasi]?',
          options: ['1888', '1890', '1900', '1870'],
          correctIndex: 0,
          topic: 'sejarah',
          validationStatus: 'draft',
          needsVerification: true,
        ),
      ];

      final run1 = generator.generate(
        lesson: lesson,
        words: sampleWords,
        phrases: samplePhrases,
        sentences: sampleSentences,
        letters: sampleLetters,
        quizBank: quizWithUnverified,
        masteredItemIds: const {},
        seed: 42,
      );
      final run2 = generator.generate(
        lesson: lesson,
        words: sampleWords,
        phrases: samplePhrases,
        sentences: sampleSentences,
        letters: sampleLetters,
        quizBank: quizWithUnverified,
        masteredItemIds: const {},
        seed: 42,
      );

      expect(
        run1.map((e) => '${e.type.code}:${e.prompt}').toList(),
        equals(run2.map((e) => '${e.type.code}:${e.prompt}').toList()),
      );

      // Pastikan soal needs_verification atau listen_choose (tanpa audio) tidak pernah muncul
      expect(
        run1.any((e) => e.prompt.contains('Istana Maimun [verifikasi]')),
        isFalse,
      );
      expect(
        run1.any((e) => e.type == ExerciseType.listenChoose),
        isFalse,
      );

      final scored = run1.where((e) => !e.isIntro).toList();
      expect(scored.length, inInclusiveRange(8, 12));

      final distinctTypes = scored.map((e) => e.type).toSet();
      expect(distinctTypes.length, greaterThanOrEqualTo(4));

      // Pastikan tidak ada tipe soal yang sama lebih dari 2 kali berturut-turut
      for (var i = 2; i < scored.length; i++) {
        final sameThree = scored[i].type == scored[i - 1].type &&
            scored[i].type == scored[i - 2].type;
        expect(
          sameThree,
          isFalse,
          reason: 'Tipe ${scored[i].type} muncul > 2 kali berturut-turut pada indeks $i',
        );
      }
    });

    test('LessonSessionEngine queues wrong answers at the end at most once', () {
      final exercises = <ExerciseItem>[
        const ExerciseItem(
          id: 'ex1',
          type: ExerciseType.mcqTranslate,
          prompt: 'Apa arti "kabar"?',
          options: ['kabar', 'masuk', 'terima', 'maaf'],
          correctAnswer: 'kabar',
          refItemId: 'ms-deli:w:0001',
          refItemType: 'word',
          explanation: 'kabar = kabar',
        ),
        const ExerciseItem(
          id: 'ex2',
          type: ExerciseType.mcqTranslate,
          prompt: 'Apa arti "masuk"?',
          options: ['masuk', 'kabar', 'terima', 'maaf'],
          correctAnswer: 'masuk',
          refItemId: 'ms-deli:w:0003',
          refItemType: 'word',
          explanation: 'masuk = masuk',
        ),
      ];

      final engine = LessonSessionEngine(
        exercises: exercises,
        initialHearts: 5,
        heartsEnabled: true,
      );

      // Jawab ex1 SALAH pada percobaan pertama -> harus masuk antrean ulang di akhir
      final firstOutcome = engine.submitAnswer('masuk');
      expect(firstOutcome, isFalse);
      expect(engine.hearts, 4);
      expect(engine.wrongCount, 1);
      engine.nextStep();

      // Jawab ex2 BENAR
      expect(engine.currentExercise.id, 'ex2');
      expect(engine.submitAnswer('masuk'), isTrue);
      engine.nextStep();

      // Sekarang ex1 muncul kembali sebagai soal antrean ulang (retry)
      expect(engine.isFinished, isFalse);
      expect(engine.currentExercise.id, 'ex1');
      expect(engine.currentExercise.isRetry, isTrue);

      // Jika dijawab salah lagi saat retry, TIDAK boleh diantrekan ulang untuk kedua kalinya (maks 1x ulang)
      expect(engine.submitAnswer('maaf'), isFalse);
      engine.nextStep();
      expect(engine.isFinished, isTrue);
    });
  });
}
