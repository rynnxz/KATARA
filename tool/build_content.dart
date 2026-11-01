import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main() {
  final sourceFile = File('konten/linguanusa_konten_draf_v0.1.json');
  if (!sourceFile.existsSync()) {
    stderr.writeln('File sumber tidak ditemukan: ${sourceFile.path}');
    exit(1);
  }

  final rawText = sourceFile.readAsStringSync();
  final raw = jsonDecode(rawText) as Map<String, dynamic>;
  const courseId = 'ms-deli';

  final idMapFile = File('tool/id_map.json');
  final Map<String, String> idMap = idMapFile.existsSync()
      ? (jsonDecode(idMapFile.readAsStringSync()) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()))
      : <String, String>{};

  String mapId(String prefix, String rawId, int index) {
    final key = '$courseId:$rawId';
    if (idMap.containsKey(key)) {
      return idMap[key]!;
    }
    final formatted = '$courseId:$prefix:${index.toString().padLeft(4, '0')}';
    idMap[key] = formatted;
    return formatted;
  }

  // 1. Pre-map Unit IDs (u01..u05 dari array units + u06..u10 dari referensi words Level 2)
  final rawUnits = (raw['units'] as List<dynamic>).cast<Map<String, dynamic>>();
  final inferredLevel2Units = <Map<String, dynamic>>[
    {'id': 'u06', 'judul': 'Aktivitas Harian', 'tema': 'aktivitas', 'urutan': 6, 'level_min': 2},
    {'id': 'u07', 'judul': 'Waktu & Hari', 'tema': 'waktu', 'urutan': 7, 'level_min': 2},
    {'id': 'u08', 'judul': 'Di Pekan', 'tema': 'pekan', 'urutan': 8, 'level_min': 2},
    {'id': 'u09', 'judul': 'Di Rumah', 'tema': 'rumah', 'urutan': 9, 'level_min': 2},
    {'id': 'u10', 'judul': 'Perasaan Hati', 'tema': 'perasaan', 'urutan': 10, 'level_min': 2},
  ];
  final allRawUnits = <Map<String, dynamic>>[...rawUnits];
  for (final u in inferredLevel2Units) {
    if (!allRawUnits.any((existing) => existing['id'] == u['id'])) {
      allRawUnits.add(u);
    }
  }

  final unitIdLookup = <String, String>{};
  for (var i = 0; i < allRawUnits.length; i++) {
    final rawU = allRawUnits[i];
    final rawId = rawU['id'] as String;
    unitIdLookup[rawId] = mapId('u', rawId, i + 1);
  }

  // 2. Words
  final rawWords = (raw['words'] as List<dynamic>).cast<Map<String, dynamic>>();
  final wordIdLookup = <String, String>{};
  final wordsByRawUnit = <String, List<String>>{};
  final wordsOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawWords.length; i++) {
    final w = rawWords[i];
    final rawId = w['id'] as String;
    final stableId = mapId('w', rawId, i + 1);
    wordIdLookup[rawId] = stableId;

    final rawUnitId = w['unit_id'] as String? ?? 'u01';
    wordsByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    final ragam = (w['ragam'] as String? ?? 'deli').toLowerCase();
    final register = ragam.startsWith('baku') ? 'baku' : 'deli';
    final statusRaw = (w['status_validasi'] as String? ?? 'draf').toLowerCase();
    final validationStatus = statusRaw == 'draf' ? 'draft' : statusRaw;

    wordsOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': w['deli'],
      'indonesia': w['indonesia'],
      'jawi': w['jawi'],
      'category': w['kategori'] ?? 'umum',
      'level': w['level'] ?? 1,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0001',
      'pos': w['tipe'] ?? 'benda',
      'register': register,
      'raw_register': ragam,
      'notes': w['catatan'],
      'audio_path': w['audio_path'],
      'image_path': w['image_path'],
      'validation_status': validationStatus,
    });
  }

  // 3. Phrases
  final rawPhrases = (raw['phrases'] as List<dynamic>).cast<Map<String, dynamic>>();
  final phraseIdLookup = <String, String>{};
  final phrasesByRawUnit = <String, List<String>>{};
  final phrasesOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawPhrases.length; i++) {
    final p = rawPhrases[i];
    final rawId = p['id'] as String;
    final stableId = mapId('p', rawId, i + 1);
    phraseIdLookup[rawId] = stableId;

    final rawUnitId = p['unit_id'] as String? ?? 'u01';
    phrasesByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    final statusRaw = (p['status_validasi'] as String? ?? 'draf').toLowerCase();
    final validationStatus = statusRaw == 'draf' ? 'draft' : statusRaw;

    phrasesOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': p['deli'],
      'indonesia': p['indonesia'],
      'jawi': p['jawi'],
      'level': p['level'] ?? 1,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0001',
      'audio_path': p['audio_path'],
      'cultural_note': p['catatan_budaya'] ?? p['catatan'],
      'validation_status': validationStatus,
    });
  }

  // 4. Sentences
  final rawSentences = (raw['sentences'] as List<dynamic>).cast<Map<String, dynamic>>();
  final sentenceIdLookup = <String, String>{};
  final sentencesOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawSentences.length; i++) {
    final s = rawSentences[i];
    final rawId = s['id'] as String;
    final stableId = mapId('s', rawId, i + 1);
    sentenceIdLookup[rawId] = stableId;

    final rawWordIds = (s['word_ids'] as List<dynamic>? ?? const []).cast<String>();
    final mappedWordIds = rawWordIds
        .map((wid) => wordIdLookup[wid])
        .whereType<String>()
        .toList();

    final statusRaw = (s['status_validasi'] as String? ?? 'draf').toLowerCase();
    final validationStatus = statusRaw == 'draf' ? 'draft' : statusRaw;

    sentencesOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': s['deli'],
      'indonesia': s['indonesia'],
      'word_ids': mappedWordIds,
      'level': s['level'] ?? 1,
      'validation_status': validationStatus,
    });
  }

  // 5. Dialogues
  final rawDialogues = (raw['dialogues'] as List<dynamic>).cast<Map<String, dynamic>>();
  final dialogueIdLookup = <String, String>{};
  final dialoguesByRawUnit = <String, List<String>>{};
  final dialoguesOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawDialogues.length; i++) {
    final d = rawDialogues[i];
    final rawId = d['id'] as String;
    final stableId = mapId('d', rawId, i + 1);
    dialogueIdLookup[rawId] = stableId;

    final rawUnitId = d['unit_id'] as String? ?? 'u01';
    dialoguesByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    final statusRaw = (d['status_validasi'] as String? ?? 'draf').toLowerCase();
    final validationStatus = statusRaw == 'draf' ? 'draft' : statusRaw;

    final rawLines = (d['lines'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final linesOut = rawLines
        .map((l) => {
              'order': l['urutan'] ?? 1,
              'speaker': l['speaker'] ?? 'Penutur',
              'deli': l['deli'] ?? '',
              'indonesia': l['indonesia'] ?? '',
            })
        .toList();

    dialoguesOut.add({
      'id': stableId,
      'course_id': courseId,
      'title': d['judul'],
      'level': d['level'] ?? 1,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0001',
      'validation_status': validationStatus,
      'lines': linesOut,
    });
  }

  // 6. Letters (Jawi)
  final rawLetters = (raw['letters'] as List<dynamic>).cast<Map<String, dynamic>>();
  final letterIdLookup = <String, String>{};
  final lettersOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawLetters.length; i++) {
    final l = rawLetters[i];
    final rawId = l['id'] as String;
    final stableId = mapId('j', rawId, i + 1);
    letterIdLookup[rawId] = stableId;

    final glyph = l['huruf'] as String;
    final statusRaw = (l['status_validasi'] as String? ?? 'draf').toLowerCase();
    final validationStatus = statusRaw == 'draf' ? 'draft' : statusRaw;

    lettersOut.add({
      'id': stableId,
      'course_id': courseId,
      'glyph': glyph,
      'name': l['nama'] ?? '',
      'sound': l['bunyi'] ?? '',
      'example_word_jawi': null,
      'example_word_latin': l['contoh_kata_latin'],
      'forms': {
        'isolated': glyph,
        'initial': null,
        'medial': null,
        'final': null,
      },
      'connects_to_next': l['bisa_disambung'] ?? true,
      'validation_status': validationStatus,
    });
  }

  // 7. Collection Cards & Articles
  final rawCards = (raw['collection_cards'] as List<dynamic>).cast<Map<String, dynamic>>();
  final rawArticles = (raw['articles'] as List<dynamic>).cast<Map<String, dynamic>>();

  final cardIdLookup = <String, String>{};
  for (var i = 0; i < rawCards.length; i++) {
    final rawId = rawCards[i]['id'] as String;
    cardIdLookup[rawId] = mapId('c', rawId, i + 1);
  }

  final articleIdLookup = <String, String>{};
  for (var i = 0; i < rawArticles.length; i++) {
    final rawId = rawArticles[i]['id'] as String;
    articleIdLookup[rawId] = mapId('art', rawId, i + 1);
  }

  final cardsOut = <Map<String, dynamic>>[];
  final cardUnlockUnitByArticleRaw = <String, String>{};

  for (var i = 0; i < rawCards.length; i++) {
    final c = rawCards[i];
    final rawId = c['id'] as String;
    final rawUnit = c['unit_pembuka'] as String?;
    final rawArtId = c['artikel_id'] as String?;
    if (rawArtId != null && rawUnit != null) {
      cardUnlockUnitByArticleRaw[rawArtId] = rawUnit;
    }

    final statusRaw = (c['status_validasi'] as String? ?? 'draf').toLowerCase();
    final validationStatus = statusRaw == 'draf' ? 'draft' : statusRaw;

    cardsOut.add({
      'id': cardIdLookup[rawId]!,
      'course_id': courseId,
      'name': c['nama'],
      'unlock_after_unit_id': rawUnit != null ? unitIdLookup[rawUnit] : null,
      'fact': c['fakta'],
      'image_path': c['gambar'],
      'article_id': rawArtId != null ? articleIdLookup[rawArtId] : null,
      'validation_status': validationStatus,
    });
  }

  final articlesOut = <Map<String, dynamic>>[];
  for (var i = 0; i < rawArticles.length; i++) {
    final a = rawArticles[i];
    final rawId = a['id'] as String;
    final rawCardId = a['kartu_koleksi_id'] as String?;
    final rawUnlockUnit = cardUnlockUnitByArticleRaw[rawId] ?? 'u03';
    final sumber = a['sumber'] as String?;
    final verifStatus = a['status_verifikasi'] as String? ?? 'belum_ditulis';

    articlesOut.add({
      'id': articleIdLookup[rawId]!,
      'course_id': courseId,
      'title': a['judul'],
      'body_markdown': a['isi'],
      'sources': sumber != null ? <String>[sumber] : <String>[],
      'verification_notes': verifStatus,
      'status': 'draft',
      'card_id': rawCardId != null ? cardIdLookup[rawCardId] : null,
      'unlock_after_unit_id': unitIdLookup[rawUnlockUnit],
    });
  }

  // 8. Units & Lessons
  final rawLessons = (raw['lessons'] as List<dynamic>).cast<Map<String, dynamic>>();
  // Tambahkan pelajaran kosakata untuk unit Level 2 (u06..u10)
  final allRawLessons = <Map<String, dynamic>>[...rawLessons];
  for (final u in inferredLevel2Units) {
    final uid = u['id'] as String;
    allRawLessons.add({
      'id': '${uid}_l1',
      'unit_id': uid,
      'tipe': 'kosakata',
      'urutan': 1,
      'xp': 15,
    });
    allRawLessons.add({
      'id': '${uid}_l2',
      'unit_id': uid,
      'tipe': 'review',
      'urutan': 2,
      'xp': 10,
    });
    allRawLessons.add({
      'id': '${uid}_l3',
      'unit_id': uid,
      'tipe': 'boss',
      'urutan': 3,
      'xp': 30,
    });
  }

  final lessonIdLookup = <String, String>{};
  for (var i = 0; i < allRawLessons.length; i++) {
    final rawId = allRawLessons[i]['id'] as String;
    lessonIdLookup[rawId] = mapId('l', rawId, i + 1);
  }

  String mapLessonKind(String rawTipe) {
    switch (rawTipe.toLowerCase()) {
      case 'kosakata':
        return 'vocab';
      case 'frasa':
        return 'phrase';
      case 'dialog':
        return 'dialogue';
      case 'budaya':
        return 'culture';
      case 'jawi':
        return 'jawi';
      case 'review':
        return 'review';
      case 'boss':
        return 'boss';
      default:
        return 'vocab';
    }
  }

  String mapRefId(String rawRef) {
    if (wordIdLookup.containsKey(rawRef)) return wordIdLookup[rawRef]!;
    if (phraseIdLookup.containsKey(rawRef)) return phraseIdLookup[rawRef]!;
    if (sentenceIdLookup.containsKey(rawRef)) return sentenceIdLookup[rawRef]!;
    if (dialogueIdLookup.containsKey(rawRef)) return dialogueIdLookup[rawRef]!;
    if (letterIdLookup.containsKey(rawRef)) return letterIdLookup[rawRef]!;
    return rawRef;
  }

  // Petakan ref_item dari exercises untuk melengkapi item_refs pelajaran
  final rawExercises = (raw['exercises'] as List<dynamic>).cast<Map<String, dynamic>>();
  final refsByRawLesson = <String, Set<String>>{};
  for (final ex in rawExercises) {
    final lid = ex['lesson_id'] as String?;
    if (lid == null) continue;
    final set = refsByRawLesson.putIfAbsent(lid, () => <String>{});
    final ref = ex['ref_item'];
    if (ref is String) {
      set.add(mapRefId(ref));
    } else if (ref is List) {
      for (final item in ref) {
        if (item is String) set.add(mapRefId(item));
      }
    }
  }

  final unitsOut = <Map<String, dynamic>>[];
  for (var i = 0; i < allRawUnits.length; i++) {
    final u = allRawUnits[i];
    final rawUnitId = u['id'] as String;
    final stableUnitId = unitIdLookup[rawUnitId]!;
    final unitWords = wordsByRawUnit[rawUnitId] ?? const <String>[];
    final unitPhrases = phrasesByRawUnit[rawUnitId] ?? const <String>[];
    final unitDialogues = dialoguesByRawUnit[rawUnitId] ?? const <String>[];

    final unitRawLessons = allRawLessons
        .where((l) => l['unit_id'] == rawUnitId)
        .toList()
      ..sort((a, b) => ((a['urutan'] as int?) ?? 1).compareTo((b['urutan'] as int?) ?? 1));

    final lessonsOut = <Map<String, dynamic>>[];
    for (final l in unitRawLessons) {
      final rawLid = l['id'] as String;
      final stableLid = lessonIdLookup[rawLid]!;
      final kind = mapLessonKind(l['tipe'] as String? ?? 'kosakata');
      final itemRefs = <String>{
        ...?refsByRawLesson[rawLid],
      };

      if (kind == 'vocab') {
        itemRefs.addAll(unitWords);
      } else if (kind == 'phrase') {
        itemRefs.addAll(unitPhrases.isNotEmpty ? unitPhrases : unitWords);
        for (final s in sentencesOut) {
          final wids = (s['word_ids'] as List<dynamic>).cast<String>();
          if (wids.any(unitWords.contains)) {
            itemRefs.add(s['id'] as String);
          }
        }
      } else if (kind == 'dialogue') {
        itemRefs.addAll(unitDialogues);
        itemRefs.addAll(unitPhrases.isNotEmpty ? unitPhrases : unitWords.take(6));
      } else if (kind == 'culture') {
        itemRefs.addAll(unitWords.take(6));
        itemRefs.addAll(lettersOut.take(3).map((e) => e['id'] as String));
      } else if (kind == 'review' || kind == 'boss') {
        itemRefs.addAll(unitWords);
        itemRefs.addAll(unitPhrases);
        itemRefs.addAll(unitDialogues);
      }

      if (itemRefs.isEmpty) {
        itemRefs.addAll(unitWords);
      }

      lessonsOut.add({
        'id': stableLid,
        'unit_id': stableUnitId,
        'order': l['urutan'] ?? 1,
        'kind': kind,
        'item_refs': itemRefs.toList(),
        'xp_reward': l['xp'] ?? 15,
      });
    }

    unitsOut.add({
      'id': stableUnitId,
      'course_id': courseId,
      'title': u['judul'],
      'theme': u['tema'],
      'order': u['urutan'] ?? (i + 1),
      'level': u['level_min'] ?? 1,
      'lessons': lessonsOut,
    });
  }

  // 9. Quiz Bank (dari exercises di sumber JSON)
  final quizBankOut = <Map<String, dynamic>>[];
  for (var i = 0; i < rawExercises.length; i++) {
    final ex = rawExercises[i];
    final rawId = ex['id'] as String;
    final stableId = mapId('q', rawId, i + 1);
    final tipe = ex['tipe'] as String? ?? 'pilihan_ganda';
    final rawLid = ex['lesson_id'] as String?;
    final mappedLessonId = rawLid != null ? lessonIdLookup[rawLid] : null;

    if (tipe == 'pilihan_ganda' || tipe == 'isi_kosong') {
      final correct = ex['jawaban_benar'] as String;
      final distractors = (ex['pengecoh'] as List<dynamic>? ?? const []).cast<String>();
      final options = <String>[correct, ...distractors];
      final refRaw = ex['ref_item'] as String?;

      quizBankOut.add({
        'id': stableId,
        'course_id': courseId,
        'lesson_id': mappedLessonId,
        'exercise_type': tipe == 'isi_kosong' ? 'fill_blank' : 'mcq_translate',
        'prompt': ex['prompt'],
        'options': options,
        'correct_index': 0,
        'ref_item_id': refRaw != null ? mapRefId(refRaw) : null,
        'topic': tipe,
        'validation_status': 'draft',
        'needs_verification': false,
      });
    } else if (tipe == 'pasangkan') {
      final rawPairs = (ex['jawaban_benar'] as List<dynamic>? ?? const []);
      final pairs = rawPairs
          .map((pair) {
            final list = (pair as List<dynamic>).map((e) => e.toString()).toList();
            return {'left': list[0], 'right': list[1]};
          })
          .toList();
      final refList = (ex['ref_item'] as List<dynamic>? ?? const [])
          .map((e) => mapRefId(e.toString()))
          .toList();

      quizBankOut.add({
        'id': stableId,
        'course_id': courseId,
        'lesson_id': mappedLessonId,
        'exercise_type': 'match_pairs',
        'prompt': ex['prompt'],
        'options': pairs.map((p) => '${p['left']} = ${p['right']}').toList(),
        'correct_index': 0,
        'pairs': pairs,
        'ref_item_ids': refList,
        'topic': 'pasangkan',
        'validation_status': 'draft',
        'needs_verification': false,
      });
    } else if (tipe == 'susun_kalimat') {
      final correct = ex['jawaban_benar'] as String;
      final tokens = (ex['potongan'] as List<dynamic>? ?? const []).cast<String>();
      final refRaw = ex['ref_item'] as String?;

      quizBankOut.add({
        'id': stableId,
        'course_id': courseId,
        'lesson_id': mappedLessonId,
        'exercise_type': 'build_sentence',
        'prompt': ex['prompt'],
        'options': tokens,
        'correct_index': 0,
        'correct_sentence': correct,
        'ref_item_id': refRaw != null ? mapRefId(refRaw) : null,
        'topic': 'susun_kalimat',
        'validation_status': 'draft',
        'needs_verification': false,
      });
    }
  }

  // 10. Courses, Game Config, Achievements, Credits, Manifest
  final coursesJson = {
    'languages': [
      {
        'id': 'ms',
        'name': 'Melayu',
        'tagline': 'Bahasa serumpun Nusantara',
        'order': 1,
      },
    ],
    'courses': [
      {
        'id': 'ms-deli',
        'language_id': 'ms',
        'name': 'Melayu Deli',
        'region_label': 'Medan & Sumatera Utara',
        'status': 'active',
        'accent_hex': '#F5B700',
        'content_version': 1,
        'has_jawi': true,
      },
      {
        'id': 'ms-other',
        'language_id': 'ms',
        'name': 'Melayu lainnya',
        'region_label': 'Segera hadir',
        'status': 'coming_soon',
        'accent_hex': '#9AA0A6',
        'content_version': 0,
        'has_jawi': false,
      },
    ],
  };

  final rawQuests = (raw['quests'] as List<dynamic>).cast<Map<String, dynamic>>();
  final rawShop = (raw['shop_items'] as List<dynamic>).cast<Map<String, dynamic>>();
  final defaultShopPrices = <String, int>{
    'i01': 50,
    'i02': 30,
    'i03': 100,
    'i04': 120,
    'i05': 150,
    'i06': 80,
  };

  final gameConfigJson = {
    'xp': {
      'lesson_complete': 10,
      'perfect_bonus': 5,
      'combo_step': 5,
      'combo_bonus_per_step': 1,
      'combo_bonus_max': 5,
      'review_xp': 8,
      'boss_xp': 25,
      'daily_quests_all_done_xp': 20,
      'level_multiplier': 50,
    },
    'titles': [
      {'min_level': 1, 'max_level': 4, 'title': 'Perantau'},
      {'min_level': 5, 'max_level': 9, 'title': 'Anak Pekan'},
      {'min_level': 10, 'max_level': 14, 'title': 'Penutur Muda'},
      {'min_level': 15, 'max_level': 19, 'title': 'Pandai Pantun'},
      {'min_level': 20, 'max_level': 29, 'title': 'Orang Kaya'},
      {'min_level': 30, 'max_level': 999, 'title': 'Datuk Bahasa'},
    ],
    'level_up_reward_coins_per_level': 5,
    'hearts': {
      'max': 5,
      'regen_minutes': 30,
      'hearts_enabled_from_level': 2,
    },
    'coins': {
      'lesson_min': 3,
      'lesson_max': 5,
      'daily_chest_min': 15,
      'daily_chest_max': 30,
    },
    'stars': {
      'three_stars_min_accuracy': 0.95,
      'two_stars_min_accuracy': 0.80,
    },
    'srs': {
      'intervals_days_by_strength': [1, 1, 3, 7, 14, 30],
      'wrong_reset_days': 1,
    },
    'quests_pool': rawQuests
        .map((q) => {
              'id': q['id'],
              'type': q['tipe'] == 'mingguan' ? 'weekly' : 'daily',
              'title': q['teks'],
              'target': q['target'],
              'metric': q['metrik'],
              'reward_coins': q['hadiah_koin'],
            })
        .toList(),
    'shop_items': rawShop
        .map((item) => {
              'id': item['id'],
              'name': item['nama'],
              'category': item['jenis'],
              'price_coins': item['harga_koin'] ?? defaultShopPrices[item['id']] ?? 50,
            })
        .toList(),
  };

  final rawAchievements =
      (raw['achievements'] as List<dynamic>).cast<Map<String, dynamic>>();
  final achievementsJson = {
    'achievements': rawAchievements
        .map((a) => {
              'id': a['id'],
              'name': a['nama'],
              'description': a['syarat'],
              'active_mvp': a['aktif_mvp'] ?? true,
            })
        .toList(),
  };

  final creditsJson = {
    'validation_notice':
        'Seluruh kosakata, frasa, dialog, dan artikel budaya saat ini berstatus Draf dan sedang dalam tahap pemeriksaan penutur asli Melayu Deli serta verifikasi ahli.',
    'contributors': <Map<String, dynamic>>[],
  };

  void writePrettyJson(String path, Object data) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(data)}\n');
  }

  writePrettyJson('tool/id_map.json', idMap);
  writePrettyJson('assets/content/courses.json', coursesJson);
  writePrettyJson('assets/content/game_config.json', gameConfigJson);
  writePrettyJson('assets/content/achievements.json', achievementsJson);
  writePrettyJson('assets/content/credits.json', creditsJson);

  writePrettyJson('assets/content/$courseId/words.json', wordsOut);
  writePrettyJson('assets/content/$courseId/phrases.json', phrasesOut);
  writePrettyJson('assets/content/$courseId/sentences.json', sentencesOut);
  writePrettyJson('assets/content/$courseId/dialogues.json', dialoguesOut);
  writePrettyJson('assets/content/$courseId/letters.json', lettersOut);
  writePrettyJson('assets/content/$courseId/articles.json', articlesOut);
  writePrettyJson('assets/content/$courseId/units.json', unitsOut);
  writePrettyJson('assets/content/$courseId/quiz_bank.json', quizBankOut);
  writePrettyJson('assets/content/$courseId/collection_cards.json', cardsOut);

  // Hitung checksum deterministik untuk manifest.json
  final digestInput = jsonEncode({
    'words': wordsOut.length,
    'phrases': phrasesOut.length,
    'sentences': sentencesOut.length,
    'dialogues': dialoguesOut.length,
    'letters': lettersOut.length,
    'articles': articlesOut.length,
    'units': unitsOut.length,
    'quiz_bank': quizBankOut.length,
    'cards': cardsOut.length,
  });
  final checksum = sha256.convert(utf8.encode(digestInput)).toString();

  final manifestJson = {
    'schema_version': 1,
    'courses': {
      courseId: {
        'content_version': 1,
        'checksum': checksum,
        'counts': {
          'words': wordsOut.length,
          'phrases': phrasesOut.length,
          'sentences': sentencesOut.length,
          'dialogues': dialoguesOut.length,
          'letters': lettersOut.length,
          'articles': articlesOut.length,
          'units': unitsOut.length,
          'lessons': allRawLessons.length,
          'quiz_bank': quizBankOut.length,
          'collection_cards': cardsOut.length,
        },
      },
    },
  };
  writePrettyJson('assets/content/manifest.json', manifestJson);

  stdout.writeln(
    'Berhasil membangun konten $courseId: '
    '${wordsOut.length} kata, ${phrasesOut.length} frasa, '
    '${sentencesOut.length} kalimat, ${dialoguesOut.length} dialog, '
    '${lettersOut.length} huruf Jawi, ${unitsOut.length} unit, '
    '${allRawLessons.length} pelajaran, ${quizBankOut.length} soal kuis.',
  );
}
