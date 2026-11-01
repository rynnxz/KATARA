import 'dart:convert';

class LanguageModel {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.order,
  });

  final String id;
  final String name;
  final String tagline;
  final int order;

  factory LanguageModel.fromJson(Map<String, dynamic> json) => LanguageModel(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: json['tagline'] as String? ?? '',
        order: (json['order'] as num?)?.toInt() ?? 1,
      );
}

class CourseModel {
  const CourseModel({
    required this.id,
    required this.languageId,
    required this.name,
    required this.regionLabel,
    required this.status,
    required this.accentHex,
    required this.contentVersion,
    required this.hasJawi,
  });

  final String id;
  final String languageId;
  final String name;
  final String regionLabel;
  final String status;
  final String accentHex;
  final int contentVersion;
  final bool hasJawi;

  bool get isActive => status == 'active';

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String,
        languageId: json['language_id'] as String,
        name: json['name'] as String,
        regionLabel: json['region_label'] as String? ?? '',
        status: json['status'] as String? ?? 'coming_soon',
        accentHex: json['accent_hex'] as String? ?? '#F5B700',
        contentVersion: (json['content_version'] as num?)?.toInt() ?? 0,
        hasJawi: json['has_jawi'] == true || json['has_jawi'] == 1,
      );
}

class WordModel {
  const WordModel({
    required this.id,
    required this.courseId,
    required this.deli,
    required this.indonesia,
    required this.category,
    required this.level,
    required this.unitId,
    required this.pos,
    required this.register,
    required this.rawRegister,
    required this.validationStatus,
    this.jawi,
    this.notes,
    this.audioPath,
    this.imagePath,
    this.deprecated = false,
  });

  final String id;
  final String courseId;
  final String deli;
  final String indonesia;
  final String? jawi;
  final String category;
  final int level;
  final String unitId;
  final String pos;
  final String register;
  final String rawRegister;
  final String? notes;
  final String? audioPath;
  final String? imagePath;
  final String validationStatus;
  final bool deprecated;

  factory WordModel.fromJson(Map<String, dynamic> json) => WordModel(
        id: json['id'] as String,
        courseId: json['course_id'] as String? ?? 'ms-deli',
        deli: json['deli'] as String,
        indonesia: json['indonesia'] as String,
        jawi: json['jawi'] as String?,
        category: json['category'] as String? ?? 'umum',
        level: (json['level'] as num?)?.toInt() ?? 1,
        unitId: json['unit_id'] as String? ?? 'ms-deli:u:0001',
        pos: json['pos'] as String? ?? 'benda',
        register: json['register'] as String? ?? 'deli',
        rawRegister: json['raw_register'] as String? ?? 'deli',
        notes: json['notes'] as String?,
        audioPath: json['audio_path'] as String?,
        imagePath: json['image_path'] as String?,
        validationStatus: json['validation_status'] as String? ?? 'draft',
        deprecated: json['deprecated'] == 1 || json['deprecated'] == true,
      );
}

class PhraseModel {
  const PhraseModel({
    required this.id,
    required this.courseId,
    required this.deli,
    required this.indonesia,
    required this.level,
    required this.unitId,
    required this.validationStatus,
    this.jawi,
    this.audioPath,
    this.culturalNote,
    this.deprecated = false,
  });

  final String id;
  final String courseId;
  final String deli;
  final String indonesia;
  final String? jawi;
  final int level;
  final String unitId;
  final String? audioPath;
  final String? culturalNote;
  final String validationStatus;
  final bool deprecated;

  factory PhraseModel.fromJson(Map<String, dynamic> json) => PhraseModel(
        id: json['id'] as String,
        courseId: json['course_id'] as String? ?? 'ms-deli',
        deli: json['deli'] as String,
        indonesia: json['indonesia'] as String,
        jawi: json['jawi'] as String?,
        level: (json['level'] as num?)?.toInt() ?? 1,
        unitId: json['unit_id'] as String? ?? 'ms-deli:u:0001',
        audioPath: json['audio_path'] as String?,
        culturalNote: json['cultural_note'] as String?,
        validationStatus: json['validation_status'] as String? ?? 'draft',
        deprecated: json['deprecated'] == 1 || json['deprecated'] == true,
      );
}

class SentenceModel {
  const SentenceModel({
    required this.id,
    required this.courseId,
    required this.deli,
    required this.indonesia,
    required this.wordIds,
    required this.level,
    required this.validationStatus,
  });

  final String id;
  final String courseId;
  final String deli;
  final String indonesia;
  final List<String> wordIds;
  final int level;
  final String validationStatus;

  factory SentenceModel.fromJson(Map<String, dynamic> json) {
    final rawWordIds = json['word_ids'] ??
        (json['word_ids_json'] != null
            ? jsonDecode(json['word_ids_json'] as String)
            : const <dynamic>[]);
    return SentenceModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      deli: json['deli'] as String,
      indonesia: json['indonesia'] as String,
      wordIds: (rawWordIds as List<dynamic>).map((e) => e.toString()).toList(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      validationStatus: json['validation_status'] as String? ?? 'draft',
    );
  }
}

class DialogueLineModel {
  const DialogueLineModel({
    required this.order,
    required this.speaker,
    required this.deli,
    required this.indonesia,
  });

  final int order;
  final String speaker;
  final String deli;
  final String indonesia;

  factory DialogueLineModel.fromJson(Map<String, dynamic> json) =>
      DialogueLineModel(
        order: (json['order'] as num?)?.toInt() ??
            (json['line_order'] as num?)?.toInt() ??
            1,
        speaker: json['speaker'] as String? ?? 'Penutur',
        deli: json['deli'] as String? ?? '',
        indonesia: json['indonesia'] as String? ?? '',
      );
}

class DialogueModel {
  const DialogueModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.level,
    required this.unitId,
    required this.validationStatus,
    required this.lines,
  });

  final String id;
  final String courseId;
  final String title;
  final int level;
  final String unitId;
  final String validationStatus;
  final List<DialogueLineModel> lines;

  factory DialogueModel.fromJson(
    Map<String, dynamic> json, [
    List<DialogueLineModel>? explicitLines,
  ]) {
    final rawLines = (json['lines'] as List<dynamic>? ?? const []);
    return DialogueModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      title: json['title'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      unitId: json['unit_id'] as String? ?? 'ms-deli:u:0001',
      validationStatus: json['validation_status'] as String? ?? 'draft',
      lines: explicitLines ??
          rawLines
              .map((e) => DialogueLineModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class JawiLetterModel {
  const JawiLetterModel({
    required this.id,
    required this.courseId,
    required this.glyph,
    required this.name,
    required this.sound,
    required this.forms,
    required this.connectsToNext,
    required this.validationStatus,
    this.exampleWordJawi,
    this.exampleWordLatin,
    this.exampleMeaningId,
    this.arabicBase,
    this.dots,
  });

  final String id;
  final String courseId;
  final String glyph;
  final String name;
  final String sound;
  final String? exampleWordJawi;
  final String? exampleWordLatin;
  final String? exampleMeaningId;
  final String? arabicBase;
  final String? dots;
  final Map<String, String?> forms;
  final bool connectsToNext;
  final String validationStatus;

  factory JawiLetterModel.fromJson(Map<String, dynamic> json) {
    final rawForms = json['forms'] ??
        (json['forms_json'] != null
            ? jsonDecode(json['forms_json'] as String)
            : <String, dynamic>{});
    final formsMap = (rawForms as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v?.toString()));
    return JawiLetterModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      glyph: json['glyph'] as String,
      name: json['name'] as String? ?? '',
      sound: json['sound'] as String? ?? '',
      exampleWordJawi: json['example_word_jawi'] as String?,
      exampleWordLatin: json['example_word_latin'] as String?,
      exampleMeaningId: json['example_meaning_id'] as String?,
      arabicBase: json['arabic_base'] as String?,
      dots: json['dots'] as String?,
      forms: formsMap,
      connectsToNext:
          json['connects_to_next'] == true || json['connects_to_next'] == 1,
      validationStatus: json['validation_status'] as String? ?? 'draft',
    );
  }
}

class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.sources,
    required this.status,
    this.bodyMarkdown,
    this.verificationNotes,
    this.cardId,
    this.unlockAfterUnitId,
  });

  final String id;
  final String courseId;
  final String title;
  final String? bodyMarkdown;
  final List<String> sources;
  final String? verificationNotes;
  final String status;
  final String? cardId;
  final String? unlockAfterUnitId;

  bool get isWritten =>
      bodyMarkdown != null && bodyMarkdown!.trim().isNotEmpty;

  String get validationStatus => status;

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] ??
        (json['sources_json'] != null
            ? jsonDecode(json['sources_json'] as String)
            : const <dynamic>[]);
    return ArticleModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      title: json['title'] as String,
      bodyMarkdown: json['body_markdown'] as String?,
      sources:
          (rawSources as List<dynamic>).map((e) => e.toString()).toList(),
      verificationNotes: json['verification_notes'] as String?,
      status: json['status'] as String? ?? 'draft',
      cardId: json['card_id'] as String?,
      unlockAfterUnitId: json['unlock_after_unit_id'] as String?,
    );
  }
}

class CollectionCardModel {
  const CollectionCardModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.validationStatus,
    this.unlockAfterUnitId,
    this.fact,
    this.imagePath,
    this.articleId,
  });

  final String id;
  final String courseId;
  final String name;
  final String? unlockAfterUnitId;
  final String? fact;
  final String? imagePath;
  final String? articleId;
  final String validationStatus;

  String get category => 'Budaya Deli';

  factory CollectionCardModel.fromJson(Map<String, dynamic> json) =>
      CollectionCardModel(
        id: json['id'] as String,
        courseId: json['course_id'] as String? ?? 'ms-deli',
        name: json['name'] as String,
        unlockAfterUnitId: json['unlock_after_unit_id'] as String?,
        fact: json['fact'] as String?,
        imagePath: json['image_path'] as String?,
        articleId: json['article_id'] as String?,
        validationStatus: json['validation_status'] as String? ?? 'draft',
      );
}

class LessonModel {
  const LessonModel({
    required this.id,
    required this.courseId,
    required this.unitId,
    required this.order,
    required this.kind,
    required this.itemRefs,
    required this.xpReward,
  });

  final String id;
  final String courseId;
  final String unitId;
  final int order;
  final String kind;
  final List<String> itemRefs;
  final int xpReward;

  String get title => displayLabel;

  String get displayLabel => switch (kind) {
        'vocab' => 'Kosakata',
        'phrase' => 'Frasa Harian',
        'dialogue' => 'Percakapan',
        'culture' => 'Budaya & Jawi',
        'jawi' => 'Aksara Jawi',
        'review' => 'Ulasan Unit',
        'boss' => 'Tantangan Boss',
        _ => 'Pelajaran',
      };

  factory LessonModel.fromJson(
    Map<String, dynamic> json, {
    String courseId = 'ms-deli',
    List<String>? explicitItemRefs,
  }) {
    final rawRefs =
        explicitItemRefs ?? (json['item_refs'] as List<dynamic>? ?? const []);
    return LessonModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? courseId,
      unitId: json['unit_id'] as String,
      order: (json['order'] as num?)?.toInt() ??
          (json['sort_order'] as num?)?.toInt() ??
          1,
      kind: json['kind'] as String? ?? 'vocab',
      itemRefs: rawRefs.map((e) => e.toString()).toList(),
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 15,
    );
  }
}

class UnitModel {
  const UnitModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.theme,
    required this.order,
    required this.level,
    required this.lessons,
  });

  final String id;
  final String courseId;
  final String title;
  final String theme;
  final int order;
  final int level;
  final List<LessonModel> lessons;

  factory UnitModel.fromJson(
    Map<String, dynamic> json, [
    List<LessonModel>? explicitLessons,
  ]) {
    final cid = json['course_id'] as String? ?? 'ms-deli';
    final rawLessons = (json['lessons'] as List<dynamic>? ?? const []);
    return UnitModel(
      id: json['id'] as String,
      courseId: cid,
      title: json['title'] as String,
      theme: json['theme'] as String? ?? 'umum',
      order: (json['order'] as num?)?.toInt() ??
          (json['sort_order'] as num?)?.toInt() ??
          1,
      level: (json['level'] as num?)?.toInt() ?? 1,
      lessons: explicitLessons ??
          rawLessons
              .map((l) => LessonModel.fromJson(
                    l as Map<String, dynamic>,
                    courseId: cid,
                  ))
              .toList(),
    );
  }
}

class QuizBankItemModel {
  const QuizBankItemModel({
    required this.id,
    required this.courseId,
    required this.exerciseType,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.topic,
    required this.validationStatus,
    required this.needsVerification,
    this.lessonId,
    this.pairs,
    this.correctSentence,
    this.refItemId,
  });

  final String id;
  final String courseId;
  final String? lessonId;
  final String exerciseType;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final List<Map<String, String>>? pairs;
  final String? correctSentence;
  final String? refItemId;
  final String topic;
  final String validationStatus;
  final bool needsVerification;

  factory QuizBankItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] ??
        (json['options_json'] != null
            ? jsonDecode(json['options_json'] as String)
            : const <dynamic>[]);
    final rawPairs = json['pairs'] ??
        (json['pairs_json'] != null && json['pairs_json'] != ''
            ? jsonDecode(json['pairs_json'] as String)
            : null);

    List<Map<String, String>>? parsedPairs;
    if (rawPairs is List) {
      parsedPairs = rawPairs
          .map((p) => {
                'left': (p as Map)['left'].toString(),
                'right': p['right'].toString(),
              })
          .toList();
    }

    return QuizBankItemModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      lessonId: json['lesson_id'] as String?,
      exerciseType: json['exercise_type'] as String? ?? 'mcq_translate',
      prompt: json['prompt'] as String,
      options: (rawOptions as List<dynamic>).map((e) => e.toString()).toList(),
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? 0,
      pairs: parsedPairs,
      correctSentence: json['correct_sentence'] as String?,
      refItemId: json['ref_item_id'] as String?,
      topic: json['topic'] as String? ?? 'umum',
      validationStatus: json['validation_status'] as String? ?? 'draft',
      needsVerification:
          json['needs_verification'] == true || json['needs_verification'] == 1,
    );
  }
}
