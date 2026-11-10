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
    this.dialectId = 'melayu_deli',
    this.isBundled = true,
    this.isInstalled = true,
    this.installedVersion = 1,
    this.downloadUrl,
    this.sha256,
    this.sizeBytes = 0,
    this.colorIdentity,
  });

  final String id;
  final String languageId;
  final String dialectId;
  final String name;
  final String regionLabel;
  final String status;
  final String accentHex;
  final int contentVersion;
  final bool hasJawi;
  final bool isBundled;
  final bool isInstalled;
  final int installedVersion;
  final String? downloadUrl;
  final String? sha256;
  final int sizeBytes;
  final Map<String, dynamic>? colorIdentity;

  bool get isActive => status == 'active';
  bool get isDownloadable => !isBundled && status != 'coming_soon';
  bool get canOpenOffline => isBundled || isInstalled;

  CourseModel copyWith({
    String? status,
    int? contentVersion,
    bool? isBundled,
    bool? isInstalled,
    int? installedVersion,
    String? downloadUrl,
    String? sha256,
    int? sizeBytes,
  }) {
    return CourseModel(
      id: id,
      languageId: languageId,
      dialectId: dialectId,
      name: name,
      regionLabel: regionLabel,
      status: status ?? this.status,
      accentHex: accentHex,
      contentVersion: contentVersion ?? this.contentVersion,
      hasJawi: hasJawi,
      isBundled: isBundled ?? this.isBundled,
      isInstalled: isInstalled ?? this.isInstalled,
      installedVersion: installedVersion ?? this.installedVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      colorIdentity: colorIdentity,
    );
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedColorIdentity;
    final rawColor = json['color_identity'] ?? json['color_identity_json'];
    if (rawColor is Map<String, dynamic>) {
      parsedColorIdentity = rawColor;
    } else if (rawColor is String && rawColor.isNotEmpty) {
      try {
        parsedColorIdentity = jsonDecode(rawColor) as Map<String, dynamic>;
      } catch (_) {}
    }

    final id = json['id'] as String;
    final defaultDialectId = switch (id) {
      'ms-langkat' => 'melayu_langkat',
      'ms-palembang' => 'melayu_palembang',
      _ => 'melayu_deli',
    };
    final bundled = json['is_bundled'] == null
        ? (id == 'ms-deli')
        : (json['is_bundled'] == true || json['is_bundled'] == 1);
    final installed = json['is_installed'] == null
        ? bundled
        : (json['is_installed'] == true || json['is_installed'] == 1);

    return CourseModel(
      id: id,
      languageId: json['language_id'] as String? ?? 'ms',
      dialectId: json['dialect_id'] as String? ?? defaultDialectId,
      name: json['name'] as String,
      regionLabel: json['region_label'] as String? ?? '',
      status: json['status'] as String? ?? 'coming_soon',
      accentHex: json['accent_hex'] as String? ?? '#F5B700',
      contentVersion: (json['content_version'] as num?)?.toInt() ?? 0,
      hasJawi: json['has_jawi'] == true || json['has_jawi'] == 1,
      isBundled: bundled,
      isInstalled: installed,
      installedVersion: (json['installed_version'] as num?)?.toInt() ??
          (installed ? ((json['content_version'] as num?)?.toInt() ?? 1) : 0),
      downloadUrl: json['download_url'] as String?,
      sha256: json['sha256'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      colorIdentity: parsedColorIdentity,
    );
  }
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
    this.pronunciation,
    this.exampleSentence,
    this.exampleTranslation,
    this.usageContext,
    this.region,
    this.variants = const [],
    this.confidence = 'high',
    this.sources = const [],
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
  final String? pronunciation;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? usageContext;
  final String? region;
  final List<String> variants;
  final String confidence;
  final List<String> sources;
  final String? audioPath;
  final String? imagePath;
  final String validationStatus;
  final bool deprecated;

  String get word => deli;
  String get meaning => indonesia;

  factory WordModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(Object? raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map) {
            return (e['id'] ?? e['title'] ?? e.toString()).toString();
          }
          return e.toString();
        }).toList();
      }
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) {
              if (e is Map) {
                return (e['id'] ?? e['title'] ?? e.toString()).toString();
              }
              return e.toString();
            }).toList();
          }
        } catch (_) {}
      }
      return const [];
    }

    return WordModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      deli: (json['deli'] ?? json['word'] ?? '') as String,
      indonesia: (json['indonesia'] ?? json['meaning'] ?? '') as String,
      jawi: json['jawi'] as String?,
      category: json['category'] as String? ?? 'umum',
      level: (json['level'] as num?)?.toInt() ?? 1,
      unitId: json['unit_id'] as String? ?? 'ms-deli:u:0001',
      pos: json['pos'] as String? ?? 'benda',
      register: json['register'] as String? ?? 'deli',
      rawRegister: json['raw_register'] as String? ?? 'deli',
      notes: json['notes'] as String?,
      pronunciation: json['pronunciation'] as String?,
      exampleSentence: json['example_sentence'] as String?,
      exampleTranslation:
          (json['example_translation'] ?? json['translation']) as String?,
      usageContext: json['usage_context'] as String?,
      region: json['region'] as String?,
      variants: parseStringList(json['variants'] ?? json['variants_json']),
      confidence: json['confidence'] as String? ?? 'high',
      sources: parseStringList(json['sources'] ?? json['sources_json']),
      audioPath: json['audio_path'] as String?,
      imagePath: json['image_path'] as String?,
      validationStatus: (json['validation_status'] ??
          json['verification_status'] ??
          'draft') as String,
      deprecated: json['deprecated'] == 1 || json['deprecated'] == true,
    );
  }
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
    this.pronunciation,
    this.region,
    this.confidence = 'high',
    this.sources = const [],
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
  final String? pronunciation;
  final String? region;
  final String confidence;
  final List<String> sources;
  final String validationStatus;
  final bool deprecated;

  factory PhraseModel.fromJson(Map<String, dynamic> json) {
    List<String> parseSources(Object? raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) {
        try {
          final d = jsonDecode(raw);
          if (d is List) return d.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return const [];
    }

    return PhraseModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      deli: (json['deli'] ?? json['expression'] ?? '') as String,
      indonesia: (json['indonesia'] ?? json['meaning'] ?? '') as String,
      jawi: json['jawi'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      unitId: json['unit_id'] as String? ?? 'ms-deli:u:0001',
      audioPath: json['audio_path'] as String?,
      culturalNote: json['cultural_note'] as String?,
      pronunciation: json['pronunciation'] as String?,
      region: json['region'] as String?,
      confidence: json['confidence'] as String? ?? 'high',
      sources: parseSources(json['sources'] ?? json['sources_json']),
      validationStatus: json['validation_status'] as String? ?? 'draft',
      deprecated: json['deprecated'] == 1 || json['deprecated'] == true,
    );
  }
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
    this.region,
    this.confidence = 'high',
    this.sources = const [],
  });

  final String id;
  final String courseId;
  final String deli;
  final String indonesia;
  final List<String> wordIds;
  final int level;
  final String? region;
  final String confidence;
  final List<String> sources;
  final String validationStatus;

  factory SentenceModel.fromJson(Map<String, dynamic> json) {
    final rawWordIds = json['word_ids'] ??
        (json['word_ids_json'] != null
            ? jsonDecode(json['word_ids_json'] as String)
            : const <dynamic>[]);
    final rawSources = json['sources'] ??
        (json['sources_json'] != null && (json['sources_json'] as String).isNotEmpty
            ? jsonDecode(json['sources_json'] as String)
            : const <dynamic>[]);
    return SentenceModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String? ?? 'ms-deli',
      deli: (json['deli'] ?? json['sentence'] ?? '') as String,
      indonesia: (json['indonesia'] ?? json['translation'] ?? '') as String,
      wordIds: (rawWordIds as List<dynamic>).map((e) => e.toString()).toList(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      region: json['region'] as String?,
      confidence: json['confidence'] as String? ?? 'high',
      sources: (rawSources as List<dynamic>).map((e) => e.toString()).toList(),
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
        deli: (json['deli'] ?? json['text'] ?? '') as String,
        indonesia: (json['indonesia'] ?? json['translation'] ?? '') as String,
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

  String get category => switch (courseId) {
        'ms-langkat' => 'Budaya Langkat',
        'ms-palembang' => 'Budaya Palembang',
        _ => 'Budaya Deli',
      };

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
        'culture' => 'Budaya & Kaidah',
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

/// Model modul dialek yang terpasang di perangkat (`installed_modules`).
class InstalledModuleModel {
  const InstalledModuleModel({
    required this.moduleId,
    required this.courseId,
    required this.version,
    required this.isBundled,
    required this.sha256,
    required this.sizeBytes,
    required this.installedAt,
    required this.updatedAt,
    this.installPath,
    this.wordCount = 0,
    this.lessonCount = 0,
  });

  final String moduleId;
  final String courseId;
  final int version;
  final bool isBundled;
  final String? installPath;
  final String sha256;
  final int sizeBytes;
  final DateTime installedAt;
  final DateTime updatedAt;
  final int wordCount;
  final int lessonCount;

  factory InstalledModuleModel.fromJson(Map<String, dynamic> json) =>
      InstalledModuleModel(
        moduleId: (json['module_id'] ?? json['course_id'] ?? 'ms-deli').toString(),
        courseId: (json['course_id'] ?? json['module_id'] ?? 'ms-deli').toString(),
        version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
        isBundled: json['is_bundled'] == true || json['is_bundled'] == 1,
        installPath: json['install_path'] as String?,
        sha256: json['sha256'] as String? ?? '',
        sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
        installedAt: DateTime.tryParse(json['installed_at']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now(),
        wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
        lessonCount: (json['lesson_count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'module_id': moduleId,
        'course_id': courseId,
        'version': version,
        'is_bundled': isBundled,
        'install_path': installPath,
        'sha256': sha256,
        'size_bytes': sizeBytes,
        'installed_at': installedAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'word_count': wordCount,
        'lesson_count': lessonCount,
      };
}

/// Model katalog modul unduhan (`module_catalog.json`).
class ModuleCatalogItemModel {
  const ModuleCatalogItemModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.regionLabel,
    required this.version,
    required this.isBundled,
    required this.accentHex,
    this.downloadUrl,
    this.sha256,
    this.sizeBytes = 0,
    this.vocabularyCount = 0,
    this.lessonCount = 0,
    this.quizCount = 0,
    this.archiveFilename,
    this.description = '',
  });

  final String id;
  final String courseId;
  final String name;
  final String regionLabel;
  final int version;
  final bool isBundled;
  final String accentHex;
  final String? downloadUrl;
  final String? sha256;
  final int sizeBytes;
  final int vocabularyCount;
  final int lessonCount;
  final int quizCount;
  final String? archiveFilename;
  final String description;

  factory ModuleCatalogItemModel.fromJson(Map<String, dynamic> json) {
    final rawId =
        (json['id'] ?? json['dialect_id'] ?? json['course_id'] ?? 'ms-deli')
            .toString();
    final cid = json['course_id'] as String? ??
        switch (rawId) {
          'melayu_langkat' => 'ms-langkat',
          'melayu_palembang' => 'ms-palembang',
          _ => rawId,
        };
    final rawVersion = json['content_version'] ?? json['version'];
    final parsedVersion = rawVersion is num
        ? rawVersion.toInt()
        : (int.tryParse(rawVersion?.toString() ?? '') ?? 1);

    return ModuleCatalogItemModel(
      id: rawId,
      courseId: cid,
      name: json['name'] as String? ?? '',
      regionLabel: json['region_label'] as String? ?? '',
      version: parsedVersion,
      isBundled: json['is_bundled'] == true || json['is_bundled'] == 1,
      accentHex: json['accent_hex'] as String? ?? '#F5B700',
      downloadUrl: json['download_url'] as String?,
      sha256: json['sha256'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      vocabularyCount:
          ((json['vocabulary_count'] ?? json['word_count']) as num?)?.toInt() ??
              0,
      lessonCount: (json['lesson_count'] as num?)?.toInt() ?? 0,
      quizCount: (json['quiz_count'] as num?)?.toInt() ?? 0,
      archiveFilename: json['archive_filename'] as String?,
      description: json['description'] as String? ?? '',
    );
  }
}

/// Model sumber referensi linguistik & budaya (`dialect_references`).
class DialectReferenceModel {
  const DialectReferenceModel({
    required this.id,
    required this.courseId,
    required this.dialectId,
    required this.title,
    required this.author,
    required this.sourceType,
    required this.reliability,
    this.publicationYear,
    this.publisher,
    this.url,
    this.accessedAt,
    this.supportedDomain,
  });

  final String id;
  final String courseId;
  final String dialectId;
  final String title;
  final String author;
  final int? publicationYear;
  final String? publisher;
  final String sourceType;
  final String? url;
  final String? accessedAt;
  final String reliability;
  final String? supportedDomain;

  factory DialectReferenceModel.fromJson(Map<String, dynamic> json) =>
      DialectReferenceModel(
        id: json['id'] as String,
        courseId: json['course_id'] as String? ?? 'ms-deli',
        dialectId: json['dialect_id'] as String? ?? 'melayu_deli',
        title: json['title'] as String,
        author: (json['author'] ??
                (json['authors'] is List
                    ? (json['authors'] as List).join(', ')
                    : 'Tim Peneliti'))
            .toString(),
        publicationYear:
            ((json['publication_year'] ?? json['year']) as num?)?.toInt(),
        publisher: (json['publisher'] ?? json['institution']) as String?,
        sourceType: (json['source_type'] ?? json['type'] ?? 'academic') as String,
        url: json['url'] as String?,
        accessedAt: json['accessed_at'] as String?,
        reliability: json['reliability'] as String? ?? 'high',
        supportedDomain:
            (json['supported_domain'] ?? json['notes']) as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'dialect_id': dialectId,
        'title': title,
        'author': author,
        'publication_year': publicationYear,
        'publisher': publisher,
        'source_type': sourceType,
        'url': url,
        'accessed_at': accessedAt,
        'reliability': reliability,
        'supported_domain': supportedDomain,
      };
}

/// Model baris perbandingan kosakata antar-dialek (Indonesia | Deli | Langkat | Palembang).
class DialectComparisonRowModel {
  const DialectComparisonRowModel({
    String? indonesia,
    String? indonesianTerm,
    required this.category,
    this.conceptId,
    this.deliWord,
    this.langkatWord,
    this.palembangWord,
    String? phonologicalNote,
    String? linguisticNote,
    String? deliTerm,
    String? deliPronunciation,
    String? langkatTerm,
    String? langkatPronunciation,
    String? palembangTerm,
    String? palembangPronunciation,
  })  : indonesia = indonesia ?? indonesianTerm ?? '',
        phonologicalNote = phonologicalNote ?? linguisticNote,
        deliTermText = deliTerm,
        deliPronunciationText = deliPronunciation,
        langkatTermText = langkatTerm,
        langkatPronunciationText = langkatPronunciation,
        palembangTermText = palembangTerm,
        palembangPronunciationText = palembangPronunciation;

  final String? conceptId;
  final String indonesia;
  final String category;
  final WordModel? deliWord;
  final WordModel? langkatWord;
  final WordModel? palembangWord;
  final String? phonologicalNote;

  final String? deliTermText;
  final String? deliPronunciationText;
  final String? langkatTermText;
  final String? langkatPronunciationText;
  final String? palembangTermText;
  final String? palembangPronunciationText;

  String get indonesianTerm => indonesia;
  String get deliTerm => deliTermText ?? deliWord?.deli ?? '-';
  String get deliPronunciation =>
      deliPronunciationText ?? deliWord?.pronunciation ?? '';
  String get langkatTerm => langkatTermText ?? langkatWord?.deli ?? '-';
  String get langkatPronunciation =>
      langkatPronunciationText ?? langkatWord?.pronunciation ?? '';
  String get palembangTerm => palembangTermText ?? palembangWord?.deli ?? '-';
  String get palembangPronunciation =>
      palembangPronunciationText ?? palembangWord?.pronunciation ?? '';
  String get linguisticNote => phonologicalNote ?? '';
}
