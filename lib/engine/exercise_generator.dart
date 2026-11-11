import 'dart:math' as math;

import 'package:katara/data/content/content_models.dart';
import 'package:katara/engine/exercise_models.dart';

/// Generator latihan murni Dart sesuai Bagian 13.1 & 13.2:
/// - Menghasilkan kartu kenalan (`intro_card`) untuk item baru
/// - Menghasilkan 8–12 latihan skor dengan >= 4 tipe berbeda bila data memungkinkan
/// - Maksimal 2 latihan bertipe sama berturut-turut
/// - Menyaring latihan audio/gambar bila path kosong dan soal `needs_verification == true`
/// - Pengecoh diambil deterministik berdasarkan `seed` dari kategori/tipe kata yang sama.
class ExerciseGenerator {
  const ExerciseGenerator();

  List<ExerciseItem> generateForLesson({
    required LessonModel lesson,
    required List<WordModel> allWords,
    required List<PhraseModel> allPhrases,
    required List<SentenceModel> allSentences,
    required List<JawiLetterModel> allLetters,
    required List<QuizBankItemModel> quizBank,
    Set<String> knownItemIds = const {},
    int? seed,
    bool includeUnverified = false,
  }) {
    return generate(
      lesson: lesson,
      words: allWords,
      phrases: allPhrases,
      sentences: allSentences,
      letters: allLetters,
      quizBank: quizBank,
      masteredItemIds: knownItemIds,
      seed: seed,
      includeUnverified: includeUnverified,
    );
  }

  List<ExerciseItem> generate({
    required LessonModel lesson,
    required List<WordModel> words,
    required List<PhraseModel> phrases,
    required List<SentenceModel> sentences,
    required List<JawiLetterModel> letters,
    required List<QuizBankItemModel> quizBank,
    List<DialogueModel> dialogues = const [],
    Set<String> masteredItemIds = const {},
    int? seed,
    bool includeUnverified = false,
  }) {
    final rng = math.Random(seed ?? lesson.id.hashCode);
    final wordById = {for (final w in words) w.id: w};
    final phraseById = {for (final p in phrases) p.id: p};
    final letterById = {for (final l in letters) l.id: l};

    final lessonWords = <WordModel>[];
    final lessonPhrases = <PhraseModel>[];
    for (final ref in lesson.itemRefs) {
      if (wordById.containsKey(ref)) {
        lessonWords.add(wordById[ref]!);
      } else if (phraseById.containsKey(ref)) {
        lessonPhrases.add(phraseById[ref]!);
      }
    }

    if (lessonWords.isEmpty && words.isNotEmpty) {
      lessonWords.addAll(words.where((w) => w.unitId == lesson.unitId).take(6));
      if (lessonWords.isEmpty) {
        lessonWords.addAll(words.take(6));
      }
    }
    if (lessonPhrases.isEmpty && phrases.isNotEmpty) {
      lessonPhrases.addAll(
        phrases.where((p) => p.unitId == lesson.unitId).take(4),
      );
      if (lessonPhrases.isEmpty) {
        lessonPhrases.addAll(phrases.take(4));
      }
    }

    // 1. Kartu kenalan untuk kata baru yang belum pernah dikuasai (maks 3 kartu agar sesi tetap ringkas)
    final introItems = <ExerciseItem>[];
    if (lesson.kind != 'review' && lesson.kind != 'boss') {
      final newWords = lessonWords
          .where((w) => !masteredItemIds.contains(w.id))
          .take(3)
          .toList();
      for (final w in newWords) {
        final exampleSentence = sentences
            .where((s) => s.wordIds.contains(w.id))
            .firstOrNull;
        introItems.add(
          ExerciseItem(
            id: 'intro:${w.id}',
            type: ExerciseType.introCard,
            prompt: w.deli,
            subtitle: w.indonesia,
            jawiText: w.jawi,
            correctAnswer: w.indonesia,
            refItemId: w.id,
            refItemType: 'word',
            explanation: exampleSentence != null
                ? 'Contoh: "${exampleSentence.deli}" (${exampleSentence.indonesia})'
                : (w.userFacingNotes ?? 'Kategori: ${w.category} (${w.pos})'),
            validationStatus: w.validationStatus,
          ),
        );
      }
    }

    // 2. Kumpulkan kandidat latihan dari berbagai tipe
    final candidatesByType = <ExerciseType, List<ExerciseItem>>{};
    void addCandidate(ExerciseItem item) {
      // Saring bila butuh audio/gambar yang belum ada
      if (item.type == ExerciseType.listenChoose &&
          (item.audioPath == null || item.audioPath!.isEmpty)) {
        return;
      }
      if (item.type == ExerciseType.imageToWord &&
          (item.imagePath == null || item.imagePath!.isEmpty)) {
        return;
      }
      candidatesByType.putIfAbsent(item.type, () => <ExerciseItem>[]).add(item);
    }

    // Tipe A: mcq_translate (Deli -> Indonesia)
    for (final w in lessonWords) {
      final distractors = _pickWordDistractors(
        target: w,
        allWords: words,
        useIndonesia: true,
        rng: rng,
      );
      final options = <String>[w.indonesia, ...distractors]..shuffle(rng);
      addCandidate(
        ExerciseItem(
          id: 'mcq_tr:${w.id}',
          type: ExerciseType.mcqTranslate,
          prompt: 'Apa arti kata "${w.deli}"?',
          options: options,
          correctAnswer: w.indonesia,
          refItemId: w.id,
          refItemType: 'word',
          explanation:
              '"${w.deli}" dalam bahasa Indonesia berarti "${w.indonesia}".',
          validationStatus: w.validationStatus,
        ),
      );
    }

    // Tipe B: mcq_reverse (Indonesia -> Deli)
    for (final w in lessonWords) {
      final distractors = _pickWordDistractors(
        target: w,
        allWords: words,
        useIndonesia: false,
        rng: rng,
      );
      final options = <String>[w.deli, ...distractors]..shuffle(rng);
      addCandidate(
        ExerciseItem(
          id: 'mcq_rev:${w.id}',
          type: ExerciseType.mcqReverse,
          prompt: 'Manakah kata Melayu Deli untuk "${w.indonesia}"?',
          options: options,
          correctAnswer: w.deli,
          refItemId: w.id,
          refItemType: 'word',
          explanation:
              '"${w.indonesia}" dalam Melayu Deli disebut "${w.deli}".',
          validationStatus: w.validationStatus,
        ),
      );
    }

    // Tipe C: match_pairs (>= 4 item)
    if (lessonWords.length >= 4) {
      final pool = List<WordModel>.from(lessonWords)..shuffle(rng);
      final selected = pool.take(4).toList();
      addCandidate(
        ExerciseItem(
          id: 'match:${lesson.id}:1',
          type: ExerciseType.matchPairs,
          prompt: 'Pasangkan kosakata Melayu Deli dengan artinya',
          correctAnswer: 'matched',
          pairs: selected
              .map(
                (w) => MatchPairItem(
                  left: w.deli,
                  right: w.indonesia,
                  itemId: w.id,
                ),
              )
              .toList(),
          refItemId: selected.first.id,
          refItemType: 'word',
          explanation: 'Semua pasangan kata telah cocok.',
        ),
      );
      if (pool.length >= 6) {
        final selected2 = pool.skip(2).take(4).toList();
        addCandidate(
          ExerciseItem(
            id: 'match:${lesson.id}:2',
            type: ExerciseType.matchPairs,
            prompt: 'Pasangkan kosakata berikut dengan tepat',
            correctAnswer: 'matched',
            pairs: selected2
                .map(
                  (w) => MatchPairItem(
                    left: w.deli,
                    right: w.indonesia,
                    itemId: w.id,
                  ),
                )
                .toList(),
            refItemId: selected2.first.id,
            refItemType: 'word',
            explanation: 'Pasangan kosakata tepat.',
          ),
        );
      }
    }

    // Tipe D: fill_blank (dari sentences atau phrases)
    final relevantSentences = sentences.isNotEmpty
        ? sentences
        : const <SentenceModel>[];
    for (final s in relevantSentences) {
      final targetWordId = s.wordIds.firstWhere(
        (wid) => wordById.containsKey(wid),
        orElse: () => '',
      );
      if (targetWordId.isEmpty) continue;
      final targetWord = wordById[targetWordId]!;
      final regex = RegExp(
        RegExp.escape(targetWord.deli),
        caseSensitive: false,
      );
      if (!regex.hasMatch(s.deli)) continue;

      final blanked = s.deli.replaceFirst(regex, '___');
      final distractors = _pickWordDistractors(
        target: targetWord,
        allWords: words,
        useIndonesia: false,
        rng: rng,
      );
      final options = <String>[targetWord.deli, ...distractors]..shuffle(rng);

      addCandidate(
        ExerciseItem(
          id: 'fill:${s.id}',
          type: ExerciseType.fillBlank,
          prompt: 'Lengkapi kalimat: "$blanked"',
          subtitle: 'Arti kalimat: "${s.indonesia}"',
          options: options,
          correctAnswer: targetWord.deli,
          refItemId: targetWord.id,
          refItemType: 'word',
          explanation: 'Kalimat lengkap: "${s.deli}" (${s.indonesia}).',
          validationStatus: s.validationStatus,
        ),
      );
    }

    // Tipe E: build_sentence (Susun potongan kata dari kalimat/frasa)
    for (final s in relevantSentences) {
      final cleanWords = s.deli
          .replaceAll(RegExp(r'[.,!?;:]'), '')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (cleanWords.length < 2) continue;

      final distractors = words
          .where(
            (w) => !cleanWords
                .map((c) => c.toLowerCase())
                .contains(w.deli.toLowerCase()),
          )
          .map((w) => w.deli)
          .take(2)
          .toList();
      final wordBank = <String>[...cleanWords, ...distractors]..shuffle(rng);

      addCandidate(
        ExerciseItem(
          id: 'build:${s.id}',
          type: ExerciseType.buildSentence,
          prompt: 'Susun kalimat Melayu Deli untuk: "${s.indonesia}"',
          wordBank: wordBank,
          correctAnswer: cleanWords.join(' '),
          refItemId: s.wordIds.isNotEmpty ? s.wordIds.first : s.id,
          refItemType: 'word',
          explanation: 'Susunan yang benar: "${s.deli}".',
          validationStatus: s.validationStatus,
        ),
      );
    }

    for (final p in lessonPhrases) {
      final cleanWords = p.deli
          .replaceAll(RegExp(r'[.,!?;:]'), '')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (cleanWords.length >= 2) {
        final wordBank = <String>[...cleanWords, 'yang']..shuffle(rng);
        addCandidate(
          ExerciseItem(
            id: 'build_p:${p.id}',
            type: ExerciseType.buildSentence,
            prompt: 'Susun ungkapan untuk: "${p.indonesia}"',
            wordBank: wordBank,
            correctAnswer: cleanWords.join(' '),
            refItemId: p.id,
            refItemType: 'phrase',
            explanation: 'Ungkapan yang tepat: "${p.deli}".',
            validationStatus: p.validationStatus,
          ),
        );
      }
    }

    // Tipe F: jawi_recognize (Huruf Jawi -> bunyi/nama)
    if (letters.length >= 4) {
      for (final l in letters) {
        final otherLetters = letters.where((x) => x.id != l.id).toList()
          ..shuffle(rng);
        final correctLabel = '${l.name} (${l.sound})';
        final distractors = otherLetters
            .take(3)
            .map((x) => '${x.name} (${x.sound})')
            .toList();
        final options = <String>[correctLabel, ...distractors]..shuffle(rng);

        addCandidate(
          ExerciseItem(
            id: 'jawi:${l.id}',
            type: ExerciseType.jawiRecognize,
            prompt: 'Huruf Jawi apakah ini?',
            jawiText: l.glyph,
            subtitle: l.exampleWordLatin != null
                ? 'Contoh bunyi pada kata "${l.exampleWordLatin}"'
                : null,
            options: options,
            correctAnswer: correctLabel,
            refItemId: l.id,
            refItemType: 'letter',
            explanation:
                'Huruf ${l.glyph} adalah "${l.name}" dengan bunyi "${l.sound}".',
            validationStatus: l.validationStatus,
          ),
        );
      }
    }

    // Tipe G: quiz_bank_item (hanya yang needsVerification == false kecuali mode debug)
    final filteredQuiz = quizBank.where((q) {
      if (!includeUnverified && q.needsVerification) return false;
      return q.lessonId == null || q.lessonId == lesson.id;
    }).toList();

    for (final q in filteredQuiz) {
      if (q.exerciseType == 'mcq_translate' || q.exerciseType == 'fill_blank') {
        if (q.options.isEmpty) continue;
        final correct =
            q.options[q.correctIndex.clamp(0, q.options.length - 1)];
        final shuffledOpts = List<String>.from(q.options)..shuffle(rng);
        addCandidate(
          ExerciseItem(
            id: 'qb:${q.id}',
            type: ExerciseType.quizBankItem,
            prompt: q.prompt,
            options: shuffledOpts,
            correctAnswer: correct,
            refItemId: q.refItemId ?? lessonWords.firstOrNull?.id,
            refItemType: letterById.containsKey(q.refItemId)
                ? 'letter'
                : 'word',
            explanation: 'Jawaban yang tepat adalah "$correct".',
            validationStatus: q.validationStatus,
          ),
        );
      }
    }

    // 3. Susun 8–12 soal dengan variasi >= 4 tipe berbeda & maks 2 tipe sama berurutan
    for (final list in candidatesByType.values) {
      list.shuffle(rng);
    }

    final targetCount = 10;
    final availableTypes = candidatesByType.keys.toList();
    final scoredResult = <ExerciseItem>[];
    final usedIds = <String>{};

    // Putaran pertama: ambil 1 soal dari setiap tipe yang tersedia agar minimal 4 tipe berbeda terpenuhi
    for (final t in availableTypes) {
      final bucket = candidatesByType[t]!;
      if (bucket.isNotEmpty && scoredResult.length < targetCount) {
        final item = bucket.removeAt(0);
        scoredResult.add(item);
        usedIds.add(item.id);
      }
    }

    // Putaran kedua: isi hingga mencapai targetCount (8–12) dengan mematuhi aturan maks 2 berturut-turut
    var guard = 0;
    while (scoredResult.length < targetCount && guard < 100) {
      guard++;
      final nonEmptyTypes = availableTypes
          .where((t) => candidatesByType[t]!.isNotEmpty)
          .toList();
      if (nonEmptyTypes.isEmpty) break;

      // Cari tipe yang tidak melanggar aturan "maksimal 2 berturut-turut"
      ExerciseType? chosenType;
      for (final t in nonEmptyTypes) {
        final len = scoredResult.length;
        final wouldRepeatThree =
            len >= 2 &&
            scoredResult[len - 1].type == t &&
            scoredResult[len - 2].type == t;
        if (!wouldRepeatThree) {
          chosenType = t;
          break;
        }
      }

      chosenType ??= nonEmptyTypes.first;
      final nextItem = candidatesByType[chosenType]!.removeAt(0);
      if (!usedIds.contains(nextItem.id)) {
        scoredResult.add(nextItem);
        usedIds.add(nextItem.id);
      }
    }

    // Rapikan urutan jika ada 3 tipe sama berturut-turut di akhir
    _enforceMaxTwoConsecutive(scoredResult);

    return <ExerciseItem>[...introItems, ...scoredResult];
  }

  List<String> _pickWordDistractors({
    required WordModel target,
    required List<WordModel> allWords,
    required bool useIndonesia,
    required math.Random rng,
  }) {
    final targetVal = (useIndonesia ? target.indonesia : target.deli)
        .toLowerCase()
        .trim();

    String valueOf(WordModel w) => useIndonesia ? w.indonesia : w.deli;

    bool isValidCandidate(WordModel w) {
      if (w.id == target.id) return false;
      if (w.deli.toLowerCase().trim() == target.deli.toLowerCase().trim()) {
        return false;
      }
      if (w.indonesia.toLowerCase().trim() ==
          target.indonesia.toLowerCase().trim()) {
        return false;
      }
      return valueOf(w).toLowerCase().trim() != targetVal;
    }

    // Prioritas 1: kategori & kelas kata (pos) yang sama
    final tier1 =
        allWords
            .where(
              (w) =>
                  isValidCandidate(w) &&
                  w.category == target.category &&
                  w.pos == target.pos,
            )
            .toList()
          ..shuffle(rng);

    // Prioritas 2: kategori yang sama
    final tier2 =
        allWords
            .where((w) => isValidCandidate(w) && w.category == target.category)
            .toList()
          ..shuffle(rng);

    // Prioritas 3: kata lain dalam course
    final tier3 = allWords.where(isValidCandidate).toList()..shuffle(rng);

    final chosen = <String>[];
    final seenLower = <String>{targetVal};

    for (final pool in [tier1, tier2, tier3]) {
      for (final w in pool) {
        if (chosen.length >= 3) break;
        final text = valueOf(w);
        final lower = text.toLowerCase().trim();
        if (!seenLower.contains(lower)) {
          seenLower.add(lower);
          chosen.add(text);
        }
      }
      if (chosen.length >= 3) break;
    }

    return chosen;
  }

  void _enforceMaxTwoConsecutive(List<ExerciseItem> items) {
    for (var i = 2; i < items.length; i++) {
      if (items[i].type == items[i - 1].type &&
          items[i].type == items[i - 2].type) {
        // Cari elemen berikutnya yang punya tipe berbeda untuk ditukar
        for (var j = i + 1; j < items.length; j++) {
          if (items[j].type != items[i].type) {
            final tmp = items[i];
            items[i] = items[j];
            items[j] = tmp;
            break;
          }
        }
      }
    }
  }
}
