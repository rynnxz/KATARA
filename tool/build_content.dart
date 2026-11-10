import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main() {
  final sourceFile = File('konten/linguanusa_konten_draf_v0.1.json');
  if (!sourceFile.existsSync()) {
    stderr.writeln('File sumber tidak ditemukan: ${sourceFile.path}');
    exit(1);
  }

  final datasetFile =
      File('melayu-deli-dataset/curated/melayu_deli_master.json');
  if (!datasetFile.existsSync()) {
    stderr.writeln(
        'File dataset terkurasi tidak ditemukan: ${datasetFile.path}');
    exit(1);
  }

  final rawText = sourceFile.readAsStringSync();
  final raw = jsonDecode(rawText) as Map<String, dynamic>;

  final datasetText = datasetFile.readAsStringSync();
  final dataset = jsonDecode(datasetText) as Map<String, dynamic>;

  const courseId = 'ms-deli';
  const int contentVersion = 2;

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

  // Indeks sumber referensi ilmiah dari dataset (SRC-0001 s/d SRC-0012)
  final dsSources =
      (dataset['sources'] as List<dynamic>).cast<Map<String, dynamic>>();
  final sourceCitationById = <String, String>{};
  for (final s in dsSources) {
    final sid = s['source_id'] as String;
    final author = s['author'] as String? ?? '';
    final year = s['publication_year']?.toString() ?? '';
    final title = s['title'] as String? ?? '';
    final pub = s['publisher'] as String? ?? '';
    sourceCitationById[sid] = '$author ($year). $title. $pub.';
  }

  List<String> resolveCitations(List<dynamic>? sids) {
    if (sids == null) return const <String>[];
    return sids
        .map((id) => sourceCitationById[id.toString()] ?? id.toString())
        .toList();
  }

  // 1. Pre-map Unit IDs (u01..u05 dari konten/ + u06..u10 Level 2 + u11..u16 dari ekspansi dataset)
  final rawUnits =
      (raw['units'] as List<dynamic>).cast<Map<String, dynamic>>();
  final inferredLevel2Units = <Map<String, dynamic>>[
    {
      'id': 'u06',
      'judul': 'Aktivitas Harian',
      'tema': 'aktivitas',
      'urutan': 6,
      'level_min': 2,
    },
    {
      'id': 'u07',
      'judul': 'Waktu & Hari',
      'tema': 'waktu',
      'urutan': 7,
      'level_min': 2,
    },
    {
      'id': 'u08',
      'judul': 'Di Pekan',
      'tema': 'pekan',
      'urutan': 8,
      'level_min': 2,
    },
    {
      'id': 'u09',
      'judul': 'Di Rumah',
      'tema': 'rumah',
      'urutan': 9,
      'level_min': 2,
    },
    {
      'id': 'u10',
      'judul': 'Perasaan Hati',
      'tema': 'perasaan',
      'urutan': 10,
      'level_min': 2,
    },
  ];
  final datasetExpansionUnits = <Map<String, dynamic>>[
    {
      'id': 'u11',
      'judul': 'Sapaan Adat & Kekerabatan',
      'tema': 'keluarga',
      'urutan': 11,
      'level_min': 2,
    },
    {
      'id': 'u12',
      'judul': 'Tindakan & Kerja Kampung',
      'tema': 'aktivitas',
      'urutan': 12,
      'level_min': 2,
    },
    {
      'id': 'u13',
      'judul': 'Sifat, Rasa & Perangai',
      'tema': 'sifat',
      'urutan': 13,
      'level_min': 2,
    },
    {
      'id': 'u14',
      'judul': 'Kuliner & Dapur Deli',
      'tema': 'makanan',
      'urutan': 14,
      'level_min': 3,
    },
    {
      'id': 'u15',
      'judul': 'Busana, Adat & Pesisir',
      'tema': 'budaya',
      'urutan': 15,
      'level_min': 3,
    },
    {
      'id': 'u16',
      'judul': 'Kata Tugas & Percakapan',
      'tema': 'percakapan',
      'urutan': 16,
      'level_min': 3,
    },
  ];

  final allRawUnits = <Map<String, dynamic>>[
    ...rawUnits,
    ...inferredLevel2Units,
    ...datasetExpansionUnits,
  ];

  final unitIdLookup = <String, String>{};
  for (var i = 0; i < allRawUnits.length; i++) {
    final rawU = allRawUnits[i];
    final rawId = rawU['id'] as String;
    unitIdLookup[rawId] = mapId('u', rawId, i + 1);
  }

  // Indeks kosakata terkurasi dari dataset
  final dsVocab =
      (dataset['vocabulary'] as List<dynamic>).cast<Map<String, dynamic>>();
  final dsVocabByLegacyId = <String, Map<String, dynamic>>{};
  final dsNewVocab = <Map<String, dynamic>>[];

  for (final v in dsVocab) {
    final leg = v['katara_legacy_id'] as String?;
    if (leg != null && leg.isNotEmpty) {
      dsVocabByLegacyId[leg] = v;
    } else {
      dsNewVocab.add(v);
    }
  }

  String buildEnrichedNotes(Map<String, dynamic> dsEntry, String? legacyNote) {
    final parts = <String>[];
    final pron = dsEntry['pronunciation'] as String?;
    if (pron != null && pron.isNotEmpty) {
      parts.add('Lafal: $pron');
    }
    final variants =
        (dsEntry['variants'] as List<dynamic>? ?? const []).cast<String>();
    if (variants.isNotEmpty) {
      parts.add('Varian: ${variants.join(', ')}');
    }
    final ex = dsEntry['example_sentence'] as String?;
    final exTr = dsEntry['example_translation'] as String?;
    if (ex != null && ex.isNotEmpty) {
      parts.add('Contoh: "$ex"${exTr != null ? ' ($exTr)' : ''}');
    }
    final note = dsEntry['notes'] as String? ?? legacyNote;
    if (note != null && note.isNotEmpty) {
      parts.add(note);
    }
    return parts.join(' • ');
  }

  // 2. Words (67 legacy words enriched + 143 new curated words = 210 words)
  final rawWords = (raw['words'] as List<dynamic>).cast<Map<String, dynamic>>();
  final wordIdLookup = <String, String>{};
  final mdVocabIdLookup = <String, String>{};
  final wordsByRawUnit = <String, List<String>>{};
  final wordsOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawWords.length; i++) {
    final w = rawWords[i];
    final rawId = w['id'] as String;
    final stableId = mapId('w', rawId, i + 1);
    wordIdLookup[rawId] = stableId;

    final dsMatch = dsVocabByLegacyId[rawId];
    if (dsMatch != null) {
      mdVocabIdLookup[dsMatch['id'] as String] = stableId;
    }

    final rawUnitId = w['unit_id'] as String? ?? 'u01';
    wordsByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    final ragam = (w['ragam'] as String? ?? 'deli').toLowerCase();
    final register = ragam.startsWith('baku') ? 'baku' : 'deli';

    String validationStatus = 'draft';
    if (dsMatch != null && dsMatch['verification_status'] == 'verified') {
      validationStatus = 'speaker_checked';
    }

    final enrichedNotes = dsMatch != null
        ? buildEnrichedNotes(dsMatch, w['catatan'] as String?)
        : (w['catatan'] as String?);

    wordsOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': w['deli'],
      'indonesia': dsMatch != null ? dsMatch['meaning_id'] : w['indonesia'],
      'jawi': dsMatch != null
          ? (dsMatch['jawi_script'] ?? dsMatch['jawi'])
          : w['jawi'],
      'category': w['kategori'] ?? 'umum',
      'level': w['level'] ?? 1,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0001',
      'pos': w['tipe'] ?? 'benda',
      'register': register,
      'raw_register': ragam,
      'notes': enrichedNotes,
      'audio_path': w['audio_path'],
      'image_path': w['image_path'],
      'validation_status': validationStatus,
      'pronunciation': dsMatch?['pronunciation'] ?? '[${w['deli']}]',
      'example_sentence': dsMatch?['example_sentence'] ?? '',
      'example_translation': dsMatch?['example_translation'] ?? '',
      'region': dsMatch?['region'] ?? 'Medan & Deli Serdang',
      'variants': dsMatch?['variants'] ?? const <String>[],
      'confidence': dsMatch?['confidence'] ?? 'high',
      'sources': dsMatch?['sources'] ?? dsMatch?['source_ids'] ?? const ['SRC-0001'],
    });
  }

  String mapPosToTipe(String pos) {
    switch (pos) {
      case 'noun':
        return 'benda';
      case 'verb':
        return 'kerja';
      case 'adjective':
        return 'sifat';
      case 'adverb':
        return 'keterangan';
      case 'pronoun':
        return 'ganti';
      case 'numeral':
        return 'angka';
      case 'preposition':
        return 'depan';
      case 'conjunction':
        return 'hubung';
      case 'interjection':
        return 'seru';
      case 'particle':
        return 'partikel';
      default:
        return 'benda';
    }
  }

  (String appCategory, String rawUnitId, int level) mapDatasetVocabPlacement(
    Map<String, dynamic> v,
  ) {
    final dsCat = v['category'] as String? ?? '';
    final pos = v['part_of_speech'] as String? ?? 'noun';
    switch (dsCat) {
      case 'pronouns':
        return ('pronomina_tanya', 'u11', 2);
      case 'greetings_and_address':
        return ('sapaan', 'u11', 2);
      case 'kinship':
        return ('keluarga', 'u11', 2);
      case 'numbers':
        return ('angka', 'u11', 2);
      case 'daily_activities':
        return ('kerja', 'u12', 2);
      case 'qualities_and_emotions':
        final term = (v['normalized_term'] as String? ?? '');
        if (['penat', 'letih', 'pening', 'segan', 'degil'].contains(term)) {
          return ('perasaan', 'u13', 2);
        }
        return ('sifat', 'u13', 2);
      case 'food_and_drink':
        return ('makanan', 'u14', 3);
      case 'household':
        return ('tempat_benda', 'u14', 3);
      case 'culture_and_customs':
        return (pos == 'verb' ? 'kerja' : 'tempat_benda', 'u15', 3);
      case 'environment_and_livelihood':
        return ('tempat_benda', 'u15', 3);
      case 'time_and_aspect':
        return ('waktu_arah', 'u16', 3);
      case 'grammar_and_particles':
      case 'connectors':
      case 'exclamations':
      default:
        return ('sapaan', 'u16', 3);
    }
  }

  for (var i = 0; i < dsNewVocab.length; i++) {
    final v = dsNewVocab[i];
    final mdId = v['id'] as String;
    final seqIndex = rawWords.length + i + 1;
    final rawKey = 'w${seqIndex.toString().padLeft(3, '0')}';
    final stableId = mapId('w', rawKey, seqIndex);
    wordIdLookup[rawKey] = stableId;
    mdVocabIdLookup[mdId] = stableId;

    final placement = mapDatasetVocabPlacement(v);
    final appCat = placement.$1;
    final rawUnitId = placement.$2;
    final lvl = placement.$3;

    wordsByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    final verif = v['verification_status'] as String? ?? 'verified';
    final valStatus = verif == 'verified' ? 'speaker_checked' : 'draft';

    wordsOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': v['term'],
      'indonesia': v['meaning_id'],
      'jawi': v['jawi_script'] ?? v['jawi'],
      'category': appCat,
      'level': lvl,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0011',
      'pos': mapPosToTipe(v['part_of_speech'] as String? ?? 'noun'),
      'register': 'deli',
      'raw_register': 'deli',
      'notes': buildEnrichedNotes(v, null),
      'audio_path': null,
      'image_path': null,
      'validation_status': valStatus,
      'pronunciation': v['pronunciation'] ?? '[${v['term']}]',
      'example_sentence': v['example_sentence'] ?? '',
      'example_translation': v['example_translation'] ?? '',
      'region': v['region'] ?? 'Medan & Deli Serdang',
      'variants': v['variants'] ?? const <String>[],
      'confidence': v['confidence'] ?? 'high',
      'sources': v['sources'] ?? v['source_ids'] ?? const ['SRC-0002'],
    });
  }

  // 3. Phrases (10 legacy phrases enriched + 30 new curated expressions = 40 phrases)
  final rawPhrases =
      (raw['phrases'] as List<dynamic>).cast<Map<String, dynamic>>();
  final dsExpressions =
      (dataset['expressions'] as List<dynamic>).cast<Map<String, dynamic>>();
  final dsExpByLegacyId = <String, Map<String, dynamic>>{};
  final dsNewExpressions = <Map<String, dynamic>>[];

  for (final e in dsExpressions) {
    final leg = e['katara_legacy_id'] as String?;
    if (leg != null && leg.isNotEmpty) {
      dsExpByLegacyId[leg] = e;
    } else {
      dsNewExpressions.add(e);
    }
  }

  final phraseIdLookup = <String, String>{};
  final phrasesByRawUnit = <String, List<String>>{};
  final phrasesOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawPhrases.length; i++) {
    final p = rawPhrases[i];
    final rawId = p['id'] as String;
    final stableId = mapId('p', rawId, i + 1);
    phraseIdLookup[rawId] = stableId;

    final dsMatch = dsExpByLegacyId[rawId];
    final rawUnitId = p['unit_id'] as String? ?? 'u01';
    phrasesByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    String valStatus = 'draft';
    if (dsMatch != null && dsMatch['verification_status'] == 'verified') {
      valStatus = 'speaker_checked';
    }

    phrasesOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': p['deli'],
      'indonesia': dsMatch != null ? dsMatch['meaning_id'] : p['indonesia'],
      'jawi': dsMatch != null ? dsMatch['jawi_script'] : p['jawi'],
      'level': p['level'] ?? 1,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0001',
      'audio_path': p['audio_path'],
      'cultural_note': dsMatch != null
          ? (dsMatch['cultural_note'] ?? dsMatch['notes'])
          : (p['catatan_budaya'] ?? p['catatan']),
      'validation_status': valStatus,
    });
  }

  String mapExpressionToRawUnit(Map<String, dynamic> e, int index) {
    final cat = e['category'] as String? ?? '';
    switch (cat) {
      case 'greeting':
      case 'gratitude':
      case 'apology':
      case 'polite_formal':
        return 'u11';
      case 'request_help':
      case 'agreement_refusal':
        return 'u12';
      case 'emotion':
        return 'u13';
      case 'socializing':
        return index.isEven ? 'u14' : 'u15';
      case 'question':
      case 'informal_slang':
      default:
        return 'u16';
    }
  }

  for (var i = 0; i < dsNewExpressions.length; i++) {
    final e = dsNewExpressions[i];
    final seqIndex = rawPhrases.length + i + 1;
    final rawKey = 'p${seqIndex.toString().padLeft(3, '0')}';
    final stableId = mapId('p', rawKey, seqIndex);
    phraseIdLookup[rawKey] = stableId;

    final rawUnitId = mapExpressionToRawUnit(e, i);
    phrasesByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    final verif = e['verification_status'] as String? ?? 'verified';
    final valStatus = verif == 'verified' ? 'speaker_checked' : 'draft';
    final lvl = ['u14', 'u15', 'u16'].contains(rawUnitId) ? 3 : 2;

    phrasesOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': e['expression'],
      'indonesia': e['meaning_id'],
      'jawi': e['jawi_script'],
      'level': lvl,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0011',
      'audio_path': null,
      'cultural_note': e['cultural_note'] ?? e['notes'],
      'validation_status': valStatus,
    });
  }

  // 4. Sentences & 5. Dialogues
  final rawSentences =
      (raw['sentences'] as List<dynamic>).cast<Map<String, dynamic>>();
  final rawDialogues =
      (raw['dialogues'] as List<dynamic>).cast<Map<String, dynamic>>();
  final dsSentences =
      (dataset['sentences'] as List<dynamic>).cast<Map<String, dynamic>>();

  final dsNewSingleSentences = <Map<String, dynamic>>[];
  final dsNewDialogues = <Map<String, dynamic>>[];

  for (final s in dsSentences) {
    final leg = s['katara_legacy_id'] as String?;
    if (leg != null && leg.isNotEmpty) {
      continue;
    }
    if (s['dialogue_exchange'] != null) {
      dsNewDialogues.add(s);
    } else {
      dsNewSingleSentences.add(s);
    }
  }

  final sentenceIdLookup = <String, String>{};
  final sentencesOut = <Map<String, dynamic>>[];

  for (var i = 0; i < rawSentences.length; i++) {
    final s = rawSentences[i];
    final rawId = s['id'] as String;
    final stableId = mapId('s', rawId, i + 1);
    sentenceIdLookup[rawId] = stableId;

    final rawWordIds =
        (s['word_ids'] as List<dynamic>? ?? const []).cast<String>();
    final mappedWordIds = rawWordIds
        .map((wid) => wordIdLookup[wid])
        .whereType<String>()
        .toList();

    sentencesOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': s['deli'],
      'indonesia': s['indonesia'],
      'word_ids': mappedWordIds,
      'level': s['level'] ?? 1,
      'validation_status': 'speaker_checked',
    });
  }

  for (var i = 0; i < dsNewSingleSentences.length; i++) {
    final s = dsNewSingleSentences[i];
    final seqIndex = rawSentences.length + i + 1;
    final rawKey = 's${seqIndex.toString().padLeft(3, '0')}';
    final stableId = mapId('s', rawKey, seqIndex);
    sentenceIdLookup[rawKey] = stableId;

    final relMdIds =
        (s['related_vocab_ids'] as List<dynamic>? ?? const []).cast<String>();
    final mappedWordIds = relMdIds
        .map((mdId) => mdVocabIdLookup[mdId])
        .whereType<String>()
        .toList();

    sentencesOut.add({
      'id': stableId,
      'course_id': courseId,
      'deli': s['sentence_deli'],
      'indonesia': s['translation_id'],
      'word_ids': mappedWordIds,
      'level': i < 12 ? 2 : 3,
      'validation_status': 'speaker_checked',
    });
  }

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

    final rawLines =
        (d['lines'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
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
      'validation_status': 'speaker_checked',
      'lines': linesOut,
    });
  }

  const newDialoguePlacement = <(String title, String rawUnitId, int level)>[
    ('Berbelanja Ikan di Pekan', 'u08', 2),
    ('Persiapan Kenduri Keluarga', 'u14', 3),
    ('Menjenguk Atok dan Andung', 'u11', 2),
  ];

  for (var i = 0; i < dsNewDialogues.length; i++) {
    final d = dsNewDialogues[i];
    final seqIndex = rawDialogues.length + i + 1;
    final rawKey = 'd${seqIndex.toString().padLeft(3, '0')}';
    final stableId = mapId('d', rawKey, seqIndex);
    dialogueIdLookup[rawKey] = stableId;

    final placement = i < newDialoguePlacement.length
        ? newDialoguePlacement[i]
        : ('Percakapan Melayu Deli $seqIndex', 'u16', 3);
    final rawUnitId = placement.$2;
    dialoguesByRawUnit.putIfAbsent(rawUnitId, () => <String>[]).add(stableId);

    final exchange = (d['dialogue_exchange'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final linesOut = <Map<String, dynamic>>[];
    for (var idx = 0; idx < exchange.length; idx++) {
      final turn = exchange[idx];
      linesOut.add({
        'order': idx + 1,
        'speaker': turn['speaker'] ?? 'Penutur',
        'deli': turn['deli'] ?? '',
        'indonesia': turn['indonesia'] ?? turn['id'] ?? '',
      });
    }

    dialoguesOut.add({
      'id': stableId,
      'course_id': courseId,
      'title': placement.$1,
      'level': placement.$3,
      'unit_id': unitIdLookup[rawUnitId] ?? '$courseId:u:0011',
      'validation_status': 'speaker_checked',
      'lines': linesOut,
    });
  }

  // 6. Letters (Jawi) — enriched with example_word_jawi
  final rawLetters =
      (raw['letters'] as List<dynamic>).cast<Map<String, dynamic>>();
  final letterIdLookup = <String, String>{};
  final lettersOut = <Map<String, dynamic>>[];
  const jawiExamplesByRawId = <String, String>{
    'j01': 'چاکڤ',
    'j02': 'بوڠا',
    'j03': 'ڤيڠݢن',
    'j04': 'ݢولاي',
    'j05': 'ۏيديو',
    'j06': 'ڽاموق',
  };

  for (var i = 0; i < rawLetters.length; i++) {
    final l = rawLetters[i];
    final rawId = l['id'] as String;
    final stableId = mapId('j', rawId, i + 1);
    letterIdLookup[rawId] = stableId;

    final glyph = l['huruf'] as String;

    lettersOut.add({
      'id': stableId,
      'course_id': courseId,
      'glyph': glyph,
      'name': l['nama'] ?? '',
      'sound': l['bunyi'] ?? '',
      'example_word_jawi': jawiExamplesByRawId[rawId],
      'example_word_latin': l['contoh_kata_latin'],
      'forms': {
        'isolated': glyph,
        'initial': null,
        'medial': null,
        'final': null,
      },
      'connects_to_next': l['bisa_disambung'] ?? true,
      'validation_status': 'speaker_checked',
    });
  }

  // 7. Collection Cards & Articles (Enriched from Cultural, Historical, Grammar & Idiom Knowledge Base)
  final rawCards =
      (raw['collection_cards'] as List<dynamic>).cast<Map<String, dynamic>>();
  final rawArticles =
      (raw['articles'] as List<dynamic>).cast<Map<String, dynamic>>();
  final dsCulture = (dataset['cultural_knowledge'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final dsHistory = (dataset['historical_knowledge'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final dsGrammar =
      (dataset['grammar'] as List<dynamic>).cast<Map<String, dynamic>>();
  final dsIdioms =
      (dataset['idioms'] as List<dynamic>).cast<Map<String, dynamic>>();

  Map<String, dynamic>? findCultureById(String id) {
    for (final c in dsCulture) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  // Tambahan 7 kartu koleksi baru (c06..c12)
  final extraRawCards = <Map<String, dynamic>>[
    {
      'id': 'c06',
      'nama': 'Tepak Sirih & Telangkai',
      'unit_pembuka': 'u11',
      'artikel_id': 'art06',
      'fakta': findCultureById('CUL-000008')?['summary'],
      'gambar': null,
    },
    {
      'id': 'c07',
      'nama': 'Upacara Tepung Tawar',
      'unit_pembuka': 'u11',
      'artikel_id': 'art07',
      'fakta': findCultureById('CUL-000009')?['summary'],
      'gambar': null,
    },
    {
      'id': 'c08',
      'nama': 'Baju Teluk Belanga & Kebaya Labuh',
      'unit_pembuka': 'u15',
      'artikel_id': 'art08',
      'fakta': findCultureById('CUL-000011')?['summary'],
      'gambar': null,
    },
    {
      'id': 'c09',
      'nama': 'Bubur Pedas & Anyang Pakis',
      'unit_pembuka': 'u14',
      'artikel_id': 'art09',
      'fakta': findCultureById('CUL-000012')?['summary'],
      'gambar': null,
    },
    {
      'id': 'c10',
      'nama': 'Kue Rasyidah & Manisan Halua',
      'unit_pembuka': 'u14',
      'artikel_id': 'art10',
      'fakta': findCultureById('CUL-000013')?['summary'],
      'gambar': null,
    },
    {
      'id': 'c11',
      'nama': 'Masjid Raya Al-Mashun',
      'unit_pembuka': 'u15',
      'artikel_id': 'art11',
      'fakta':
          'Masjid bersejarah Kesultanan Deli yang dibangun oleh Sultan Ma\'mun Al Rasyid pada 21 Agustus 1906 hingga 10 September 1909 dengan perpaduan arsitektur Timur Tengah, India, dan Eropa.',
      'gambar': null,
    },
    {
      'id': 'c12',
      'nama': 'Pantun & Peribahasa Melayu Deli',
      'unit_pembuka': 'u16',
      'artikel_id': 'art13',
      'fakta':
          'Khazanah sastra lisan Melayu Deli yang memadukan pantun adat peminangan Telangkai dan peribahasa bermetafora alam pesisir.',
      'gambar': null,
    },
  ];

  final allCardsRaw = <Map<String, dynamic>>[...rawCards, ...extraRawCards];
  final cardIdLookup = <String, String>{};
  for (var i = 0; i < allCardsRaw.length; i++) {
    final rawId = allCardsRaw[i]['id'] as String;
    cardIdLookup[rawId] = mapId('c', rawId, i + 1);
  }

  // Susun daftar 14 artikel budaya, sejarah, tata bahasa & peribahasa (art01..art14)
  String buildCultureArticleBody(Map<String, dynamic> cul,
      {Map<String, dynamic>? his}) {
    final sb = StringBuffer();
    sb.writeln(cul['summary']);
    sb.writeln();
    sb.writeln(cul['description']);
    if (his != null) {
      sb.writeln();
      sb.writeln('### Konteks Sejarah (${his['period']})');
      sb.writeln(his['description']);
    }
    final rel =
        (cul['related_terms'] as List<dynamic>? ?? const []).cast<String>();
    if (rel.isNotEmpty) {
      sb.writeln();
      sb.writeln('**Istilah Terkait:** ${rel.join(', ')}');
    }
    return sb.toString();
  }

  String buildGrammarCompendiumBody() {
    final sb = StringBuffer();
    sb.writeln(
        'Ringkasan 15 kaidah fonologi, morfologi, sintaksis, sosiolinguistik, dan ortografi Bahasa Melayu Deli berdasarkan penelitian Pusat Pembinaan dan Pengembangan Bahasa serta akademisi Universitas Sumatera Utara:');
    sb.writeln();
    for (final g in dsGrammar) {
      sb.writeln('### ${g['title']}');
      sb.writeln('- **Pola:** `${g['pattern_formula']}`');
      sb.writeln('- **Penjelasan:** ${g['rule_summary']}');
      sb.writeln('- **Perbandingan Bahasa Indonesia:** ${g['comparison_indonesian']}');
      final exs =
          (g['examples'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      if (exs.isNotEmpty) {
        final exStr =
            exs.map((e) => '"${e['deli']}" (${e['indonesian']})').join('; ');
        sb.writeln('- **Contoh:** $exStr');
      }
      sb.writeln();
    }
    return sb.toString().trim();
  }

  String buildIdiomsCompendiumBody() {
    final sb = StringBuffer();
    sb.writeln(
        'Kumpulan 20 peribahasa, idiom, dan pantun adat yang hidup dalam masyarakat Melayu Deli:');
    sb.writeln();
    for (final idm in dsIdioms) {
      sb.writeln('### "${idm['text_deli']}"');
      sb.writeln('- **Jenis:** ${idm['type']}');
      sb.writeln('- **Makna Harfiah:** ${idm['translation_literal_id']}');
      sb.writeln('- **Makna Kiasan / Filosofis:** ${idm['meaning_figurative_id']}');
      sb.writeln('- **Konteks Budaya:** ${idm['cultural_context']}');
      sb.writeln();
    }
    return sb.toString().trim();
  }

  String buildHistoryCompendiumBody() {
    final sb = StringBuffer();
    sb.writeln(
        'Kronologi perkembangan sejarah Kesultanan Deli, Kota Medan, dan dokumentasi Bahasa Melayu Deli dari abad ke-13 hingga abad ke-21:');
    sb.writeln();
    for (final h in dsHistory) {
      sb.writeln('### ${h['period']} — ${h['title']}');
      sb.writeln(h['description']);
      sb.writeln();
    }
    return sb.toString().trim();
  }

  final cul01 = findCultureById('CUL-000001')!;
  final cul02 = findCultureById('CUL-000002')!;
  final cul03 = findCultureById('CUL-000003')!;
  final cul05 = findCultureById('CUL-000005')!;
  final cul07 = findCultureById('CUL-000007')!;
  final cul08 = findCultureById('CUL-000008')!;
  final cul09 = findCultureById('CUL-000009')!;
  final cul10 = findCultureById('CUL-000010')!;
  final cul11 = findCultureById('CUL-000011')!;
  final cul12 = findCultureById('CUL-000012')!;
  final cul13 = findCultureById('CUL-000013')!;

  final allArticlesSpec = <Map<String, dynamic>>[
    {
      'id': 'art01',
      'title': rawArticles[0]['judul'] ?? cul01['title'],
      'body': buildCultureArticleBody(cul01, his: dsHistory[0]),
      'sources': resolveCitations(cul01['source_ids'] as List<dynamic>?),
      'notes': 'Terverifikasi melalui dokumentasi WBTb Kemendikbud & sejarah lokal Sumatera Utara.',
      'card_raw_id': 'c02',
      'unit_raw_id': 'u03',
    },
    {
      'id': 'art02',
      'title': rawArticles[1]['judul'] ?? cul02['title'],
      'body': buildCultureArticleBody(cul02, his: dsHistory[6]),
      'sources': resolveCitations(cul02['source_ids'] as List<dynamic>?),
      'notes': 'Terverifikasi: dibangun 26 Agustus 1888 – 18 Mei 1891 pada masa Sultan Ma\'mun Al Rasyid.',
      'card_raw_id': 'c01',
      'unit_raw_id': 'u03',
    },
    {
      'id': 'art03',
      'title': rawArticles[2]['judul'] ?? cul03['title'],
      'body': buildCultureArticleBody(cul03, his: dsHistory[1]),
      'sources': resolveCitations(cul03['source_ids'] as List<dynamic>?),
      'notes': 'Terverifikasi: tradisi pembukaan Kampung Medan Putri sekitar tahun 1590.',
      'card_raw_id': null,
      'unit_raw_id': 'u05',
    },
    {
      'id': 'art04',
      'title': cul05['title'],
      'body': buildCultureArticleBody(cul05),
      'sources': resolveCitations(cul05['source_ids'] as List<dynamic>?),
      'notes': 'Dokumentasi busana adat laki-laki Melayu Deli.',
      'card_raw_id': 'c03',
      'unit_raw_id': 'u02',
    },
    {
      'id': 'art05',
      'title': cul07['title'],
      'body': buildCultureArticleBody(cul07, his: dsHistory[8]),
      'sources': resolveCitations(cul07['source_ids'] as List<dynamic>?),
      'notes': 'Diciptakan oleh Guru Sauti (1938) dengan 12 ragam gerak.',
      'card_raw_id': 'c05',
      'unit_raw_id': 'u05',
    },
    {
      'id': 'art06',
      'title': cul08['title'],
      'body': buildCultureArticleBody(cul08),
      'sources': resolveCitations(cul08['source_ids'] as List<dynamic>?),
      'notes': 'Tradisi lisan peminangan adat Melayu Deli.',
      'card_raw_id': 'c06',
      'unit_raw_id': 'u11',
    },
    {
      'id': 'art07',
      'title': cul09['title'],
      'body': buildCultureArticleBody(cul09),
      'sources': resolveCitations(cul09['source_ids'] as List<dynamic>?),
      'notes': 'Upacara doa restu dan keselamatan dalam daur hidup Melayu Deli.',
      'card_raw_id': 'c07',
      'unit_raw_id': 'u11',
    },
    {
      'id': 'art08',
      'title': cul11['title'],
      'body': buildCultureArticleBody(cul11),
      'sources': resolveCitations(cul11['source_ids'] as List<dynamic>?),
      'notes': 'Busana adat tradisional Melayu Deli.',
      'card_raw_id': 'c08',
      'unit_raw_id': 'u15',
    },
    {
      'id': 'art09',
      'title': cul12['title'],
      'body': buildCultureArticleBody(cul12),
      'sources': resolveCitations(cul12['source_ids'] as List<dynamic>?),
      'notes': 'Warisan kuliner khas Ramadan di Kesultanan Deli dan Masjid Raya Al-Mashun.',
      'card_raw_id': 'c09',
      'unit_raw_id': 'u14',
    },
    {
      'id': 'art10',
      'title': cul13['title'],
      'body': buildCultureArticleBody(cul13),
      'sources': resolveCitations(cul13['source_ids'] as List<dynamic>?),
      'notes': 'Kue kehormatan adat dan manisan khas Hari Raya Melayu Deli.',
      'card_raw_id': 'c10',
      'unit_raw_id': 'u14',
    },
    {
      'id': 'art11',
      'title': cul10['title'],
      'body': buildCultureArticleBody(cul10, his: dsHistory[7]),
      'sources': resolveCitations(cul10['source_ids'] as List<dynamic>?),
      'notes': 'Sosiolinguistik sapaan kekerabatan dan gelar kebangsawanan Melayu Deli (Syarfina, 2004).',
      'card_raw_id': 'c11',
      'unit_raw_id': 'u15',
    },
    {
      'id': 'art12',
      'title': 'Kaidah Tata Bahasa & Ciri Khas Bahasa Melayu Deli',
      'body': buildGrammarCompendiumBody(),
      'sources': resolveCitations(
          ['SRC-0002', 'SRC-0003', 'SRC-0004', 'SRC-0005', 'SRC-0006']),
      'notes': 'Disusun dari 15 kaidah fonologi, morfologi, sintaksis, dan ortografi Jawi.',
      'card_raw_id': null,
      'unit_raw_id': 'u12',
    },
    {
      'id': 'art13',
      'title': 'Khazanah Peribahasa, Idiom & Pantun Adat Melayu Deli',
      'body': buildIdiomsCompendiumBody(),
      'sources': resolveCitations(['SRC-0005', 'SRC-0007', 'SRC-0008']),
      'notes': 'Mencakup peribahasa bermetafora fauna/alam dan pantun Telangkai.',
      'card_raw_id': 'c12',
      'unit_raw_id': 'u16',
    },
    {
      'id': 'art14',
      'title': 'Sejarah Kesultanan Deli & Perkembangan Bahasa Melayu Deli',
      'body': buildHistoryCompendiumBody(),
      'sources': resolveCitations(
          ['SRC-0003', 'SRC-0006', 'SRC-0009', 'SRC-0010', 'SRC-0011']),
      'notes': 'Kronologi sejarah dari Kerajaan Haru, Kesultanan Deli (1632), hingga era modern.',
      'card_raw_id': null,
      'unit_raw_id': 'u16',
    },
  ];

  final articleIdLookup = <String, String>{};
  for (var i = 0; i < allArticlesSpec.length; i++) {
    final rawId = allArticlesSpec[i]['id'] as String;
    articleIdLookup[rawId] = mapId('art', rawId, i + 1);
  }

  final verifiedCardFactsByRawId = <String, String>{
    'c01': findCultureById('CUL-000002')!['summary'] as String,
    'c02': findCultureById('CUL-000004')!['summary'] as String,
    'c03': findCultureById('CUL-000005')!['summary'] as String,
    'c04': findCultureById('CUL-000006')!['summary'] as String,
    'c05': findCultureById('CUL-000007')!['summary'] as String,
  };

  final verifiedCardArticleByRawId = <String, String>{
    'c01': 'art02',
    'c02': 'art01',
    'c03': 'art04',
    'c04': 'art09',
    'c05': 'art05',
  };

  final cardsOut = <Map<String, dynamic>>[];
  for (var i = 0; i < allCardsRaw.length; i++) {
    final c = allCardsRaw[i];
    final rawId = c['id'] as String;
    final rawUnit = c['unit_pembuka'] as String?;
    final rawArtId =
        (c['artikel_id'] as String?) ?? verifiedCardArticleByRawId[rawId];
    final factText =
        (c['fakta'] as String?) ?? verifiedCardFactsByRawId[rawId];

    cardsOut.add({
      'id': cardIdLookup[rawId]!,
      'course_id': courseId,
      'name': c['nama'],
      'unlock_after_unit_id': rawUnit != null ? unitIdLookup[rawUnit] : null,
      'fact': factText,
      'image_path': c['gambar'],
      'article_id': rawArtId != null ? articleIdLookup[rawArtId] : null,
      'validation_status': 'speaker_checked',
    });
  }

  final articlesOut = <Map<String, dynamic>>[];
  for (final a in allArticlesSpec) {
    final rawId = a['id'] as String;
    final rawCardId = a['card_raw_id'] as String?;
    final rawUnlockUnit = a['unit_raw_id'] as String? ?? 'u03';

    articlesOut.add({
      'id': articleIdLookup[rawId]!,
      'course_id': courseId,
      'title': a['title'],
      'body_markdown': a['body'],
      'sources': a['sources'],
      'verification_notes': a['notes'],
      'status': 'published',
      'card_id': rawCardId != null ? cardIdLookup[rawCardId] : null,
      'unlock_after_unit_id': unitIdLookup[rawUnlockUnit],
    });
  }

  // 8. Units & Lessons
  final rawLessons =
      (raw['lessons'] as List<dynamic>).cast<Map<String, dynamic>>();
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

  for (final u in datasetExpansionUnits) {
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
      'tipe': 'frasa',
      'urutan': 2,
      'xp': 15,
    });
    allRawLessons.add({
      'id': '${uid}_l3',
      'unit_id': uid,
      'tipe': 'review',
      'urutan': 3,
      'xp': 10,
    });
    allRawLessons.add({
      'id': '${uid}_l4',
      'unit_id': uid,
      'tipe': 'boss',
      'urutan': 4,
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

  final rawExercises =
      (raw['exercises'] as List<dynamic>).cast<Map<String, dynamic>>();
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
      ..sort((a, b) =>
          ((a['urutan'] as int?) ?? 1).compareTo((b['urutan'] as int?) ?? 1));

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
        itemRefs.addAll(
            unitPhrases.isNotEmpty ? unitPhrases : unitWords.take(6));
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
      final distractors =
          (ex['pengecoh'] as List<dynamic>? ?? const []).cast<String>();
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
        'validation_status': 'speaker_checked',
        'needs_verification': false,
      });
    } else if (tipe == 'pasangkan') {
      final rawPairs = (ex['jawaban_benar'] as List<dynamic>? ?? const []);
      final pairs = rawPairs.map((pair) {
        final list =
            (pair as List<dynamic>).map((e) => e.toString()).toList();
        return {'left': list[0], 'right': list[1]};
      }).toList();
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
        'validation_status': 'speaker_checked',
        'needs_verification': false,
      });
    } else if (tipe == 'susun_kalimat') {
      final correct = ex['jawaban_benar'] as String;
      final tokens =
          (ex['potongan'] as List<dynamic>? ?? const []).cast<String>();
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
        'validation_status': 'speaker_checked',
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
        'region_label': 'Medan & Deli Serdang, Sumatera Utara',
        'status': 'active',
        'accent_hex': '#F5B700',
        'content_version': contentVersion,
        'has_jawi': true,
        'is_bundled': true,
        'theme_key': 'deli',
        'description':
            'Bahasa Melayu pesisir timur Sumatera Utara di Medan, Labuhan Deli, dan Deli Serdang dengan ciri vokal akhir -e serta sistem sapaan kekerabatan khas.',
      },
      {
        'id': 'ms-langkat',
        'language_id': 'ms',
        'name': 'Melayu Langkat',
        'region_label': 'Tanjung Pura, Stabat & Pesisir Langkat',
        'status': 'downloadable',
        'accent_hex': '#1E7F5C',
        'content_version': 1,
        'has_jawi': true,
        'is_bundled': false,
        'theme_key': 'langkat',
        'description':
            'Bahasa Melayu Kesultanan Langkat di Tanjung Pura, Stabat, Secanggang, dan Pangkalan Brandan yang kaya sastra pantun, kuliner halua, dan ekologi muara.',
      },
      {
        'id': 'ms-palembang',
        'language_id': 'ms',
        'name': 'Melayu Palembang',
        'region_label': 'Seberang Ilir, Seberang Ulu & Tepian Musi',
        'status': 'downloadable',
        'accent_hex': '#8B1E24',
        'content_version': 1,
        'has_jawi': false,
        'is_bundled': false,
        'theme_key': 'palembang',
        'description':
            'Bahasa Melayu Palembang dengan dua tingkat tutur (Baso Palembang Alus/Bebaso dan Sari-sari), budaya Sungai Musi, Rumah Limas, serta wastra Songket.',
      },
    ],
  };

  final rawQuests =
      (raw['quests'] as List<dynamic>).cast<Map<String, dynamic>>();
  final rawShop =
      (raw['shop_items'] as List<dynamic>).cast<Map<String, dynamic>>();
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
              'price_coins': item['harga_koin'] ??
                  defaultShopPrices[item['id']] ??
                  50,
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
        'Konten Bahasa Melayu Deli telah diperkaya dan diverifikasi silang dengan 12 rujukan ilmiah (Kamus Melayu Deli-Indonesia 1985, Kamus Melayu Sumatera Utara 2018, monograf Pusat Bahasa, penelitian USU, dan WBTb Kemendikbud). Empat entri ragam baku tetap ditandai Draf untuk peninjauan penutur.',
    'contributors': dsSources
        .map((s) => {
              'source_id': s['source_id'],
              'title': s['title'],
              'author': s['author'],
              'year': s['publication_year'],
              'publisher': s['publisher'],
            })
        .toList(),
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

  final flatLessonsOut = <Map<String, dynamic>>[];
  for (final u in unitsOut) {
    final uLessons = (u['lessons'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    flatLessonsOut.addAll(uLessons);
  }
  final dsConversations =
      (dataset['conversations'] as List<dynamic>? ?? dialoguesOut)
          .cast<Map<String, dynamic>>();

  writePrettyJson('assets/content/$courseId/words.json', wordsOut);
  writePrettyJson('assets/content/$courseId/phrases.json', phrasesOut);
  writePrettyJson('assets/content/$courseId/sentences.json', sentencesOut);
  writePrettyJson('assets/content/$courseId/dialogues.json', dialoguesOut);
  writePrettyJson('assets/content/$courseId/conversations.json', dsConversations);
  writePrettyJson('assets/content/$courseId/letters.json', lettersOut);
  writePrettyJson('assets/content/$courseId/articles.json', articlesOut);
  writePrettyJson('assets/content/$courseId/units.json', unitsOut);
  writePrettyJson('assets/content/$courseId/lessons.json', flatLessonsOut);
  writePrettyJson('assets/content/$courseId/quiz_bank.json', quizBankOut);
  writePrettyJson('assets/content/$courseId/collection_cards.json', cardsOut);
  writePrettyJson('assets/content/$courseId/cultural_cards.json', cardsOut);
  writePrettyJson('assets/content/$courseId/references.json', dsSources);

  // Hitung checksum deterministik untuk manifest.json
  final digestInput = jsonEncode({
    'version': contentVersion,
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
        'content_version': contentVersion,
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
    'Berhasil membangun konten $courseId (v$contentVersion): '
    '${wordsOut.length} kata, ${phrasesOut.length} frasa, '
    '${sentencesOut.length} kalimat, ${dialoguesOut.length} dialog, '
    '${lettersOut.length} huruf Jawi, ${articlesOut.length} artikel budaya, '
    '${cardsOut.length} kartu koleksi, ${unitsOut.length} unit, '
    '${allRawLessons.length} pelajaran, ${quizBankOut.length} soal kuis.',
  );
}
