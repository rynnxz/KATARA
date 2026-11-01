import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/domain/repositories/content_repository.dart';

class LocalContentRepository implements ContentRepository {
  LocalContentRepository({
    required this.db,
    AssetStringLoader? loadAsset,
  }) : _loadAsset = loadAsset ?? rootBundle.loadString;

  final AppDatabase db;
  final AssetStringLoader _loadAsset;

  GameConfig? _cachedConfig;

  @override
  Future<List<LanguageModel>> getLanguages() async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect('SELECT * FROM languages ORDER BY sort_order ASC')
        .get();
    return rows
        .map((r) => LanguageModel(
              id: r.read<String>('id'),
              name: r.read<String>('name'),
              tagline: r.read<String>('tagline'),
              order: r.read<int>('sort_order'),
            ))
        .toList();
  }

  @override
  Future<List<CourseModel>> getCourses({String? languageId}) async {
    await db.ensureInitialized();
    final rows = languageId != null
        ? await db.customSelect(
            'SELECT * FROM courses WHERE language_id = ? ORDER BY status ASC, id ASC',
            variables: [Variable.withString(languageId)],
          ).get()
        : await db
            .customSelect('SELECT * FROM courses ORDER BY status ASC, id ASC')
            .get();
    return rows.map(_mapCourse).toList();
  }

  @override
  Future<CourseModel?> getCourse(String courseId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM courses WHERE id = ? LIMIT 1',
      variables: [Variable.withString(courseId)],
    ).get();
    if (rows.isEmpty) return null;
    return _mapCourse(rows.first);
  }

  CourseModel _mapCourse(QueryRow r) => CourseModel(
        id: r.read<String>('id'),
        languageId: r.read<String>('language_id'),
        name: r.read<String>('name'),
        regionLabel: r.read<String>('region_label'),
        status: r.read<String>('status'),
        accentHex: r.read<String>('accent_hex'),
        contentVersion: r.read<int>('content_version'),
        hasJawi: r.read<int>('has_jawi') == 1,
      );

  @override
  Future<List<UnitModel>> getUnits(String courseId) async {
    await db.ensureInitialized();
    final unitRows = await db.customSelect(
      'SELECT * FROM units WHERE course_id = ? AND deprecated = 0 ORDER BY sort_order ASC',
      variables: [Variable.withString(courseId)],
    ).get();

    final lessonRows = await db.customSelect(
      'SELECT * FROM lessons WHERE course_id = ? AND deprecated = 0 ORDER BY sort_order ASC',
      variables: [Variable.withString(courseId)],
    ).get();

    final itemRows = await db.customSelect(
      'SELECT * FROM lesson_items WHERE course_id = ? ORDER BY sort_order ASC',
      variables: [Variable.withString(courseId)],
    ).get();

    final itemsByLesson = <String, List<String>>{};
    for (final ir in itemRows) {
      final lid = ir.read<String>('lesson_id');
      itemsByLesson.putIfAbsent(lid, () => <String>[]).add(ir.read<String>('item_id'));
    }

    final lessonsByUnit = <String, List<LessonModel>>{};
    for (final lr in lessonRows) {
      final lid = lr.read<String>('id');
      final uid = lr.read<String>('unit_id');
      lessonsByUnit.putIfAbsent(uid, () => <LessonModel>[]).add(
            LessonModel(
              id: lid,
              courseId: lr.read<String>('course_id'),
              unitId: uid,
              order: lr.read<int>('sort_order'),
              kind: lr.read<String>('kind'),
              itemRefs: itemsByLesson[lid] ?? const <String>[],
              xpReward: lr.read<int>('xp_reward'),
            ),
          );
    }

    return unitRows.map((ur) {
      final uid = ur.read<String>('id');
      return UnitModel(
        id: uid,
        courseId: ur.read<String>('course_id'),
        title: ur.read<String>('title'),
        theme: ur.read<String>('theme'),
        order: ur.read<int>('sort_order'),
        level: ur.read<int>('level'),
        lessons: lessonsByUnit[uid] ?? const <LessonModel>[],
      );
    }).toList();
  }

  @override
  Future<UnitModel?> getUnit(String unitId) async {
    await db.ensureInitialized();
    final unitRows = await db.customSelect(
      'SELECT * FROM units WHERE id = ? LIMIT 1',
      variables: [Variable.withString(unitId)],
    ).get();
    if (unitRows.isEmpty) return null;
    final courseId = unitRows.first.read<String>('course_id');
    final allUnits = await getUnits(courseId);
    for (final u in allUnits) {
      if (u.id == unitId) return u;
    }
    return null;
  }

  @override
  Future<LessonModel?> getLesson(String lessonId) async {
    await db.ensureInitialized();
    final lr = await db.customSelect(
      'SELECT * FROM lessons WHERE id = ? LIMIT 1',
      variables: [Variable.withString(lessonId)],
    ).get();
    if (lr.isEmpty) return null;
    final row = lr.first;
    final itemRows = await db.customSelect(
      'SELECT item_id FROM lesson_items WHERE lesson_id = ? ORDER BY sort_order ASC',
      variables: [Variable.withString(lessonId)],
    ).get();

    return LessonModel(
      id: row.read<String>('id'),
      courseId: row.read<String>('course_id'),
      unitId: row.read<String>('unit_id'),
      order: row.read<int>('sort_order'),
      kind: row.read<String>('kind'),
      itemRefs: itemRows.map((r) => r.read<String>('item_id')).toList(),
      xpReward: row.read<int>('xp_reward'),
    );
  }

  @override
  Future<List<WordModel>> getWords(
    String courseId, {
    String? category,
    String? query,
  }) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM words WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
      variables: [Variable.withString(courseId)],
    ).get();

    var list = rows
        .map((r) => WordModel(
              id: r.read<String>('id'),
              courseId: r.read<String>('course_id'),
              deli: r.read<String>('deli'),
              indonesia: r.read<String>('indonesia'),
              jawi: r.readNullable<String>('jawi'),
              category: r.read<String>('category'),
              level: r.read<int>('level'),
              unitId: r.read<String>('unit_id'),
              pos: r.read<String>('pos'),
              register: r.read<String>('register'),
              rawRegister: r.read<String>('raw_register'),
              notes: r.readNullable<String>('notes'),
              audioPath: r.readNullable<String>('audio_path'),
              imagePath: r.readNullable<String>('image_path'),
              validationStatus: r.read<String>('validation_status'),
              deprecated: r.read<int>('deprecated') == 1,
            ))
        .toList();

    if (category != null && category.isNotEmpty && category != 'semua') {
      list = list.where((w) => w.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list
          .where((w) =>
              w.deli.toLowerCase().contains(q) ||
              w.indonesia.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Future<List<PhraseModel>> getPhrases(String courseId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM phrases WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
      variables: [Variable.withString(courseId)],
    ).get();
    return rows
        .map((r) => PhraseModel(
              id: r.read<String>('id'),
              courseId: r.read<String>('course_id'),
              deli: r.read<String>('deli'),
              indonesia: r.read<String>('indonesia'),
              jawi: r.readNullable<String>('jawi'),
              level: r.read<int>('level'),
              unitId: r.read<String>('unit_id'),
              audioPath: r.readNullable<String>('audio_path'),
              culturalNote: r.readNullable<String>('cultural_note'),
              validationStatus: r.read<String>('validation_status'),
              deprecated: r.read<int>('deprecated') == 1,
            ))
        .toList();
  }

  @override
  Future<List<SentenceModel>> getSentences(String courseId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM sentences WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
      variables: [Variable.withString(courseId)],
    ).get();
    return rows.map((r) => SentenceModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<DialogueModel>> getDialogues(String courseId) async {
    await db.ensureInitialized();
    final dRows = await db.customSelect(
      'SELECT * FROM dialogues WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
      variables: [Variable.withString(courseId)],
    ).get();
    final lRows = await db.customSelect(
      'SELECT * FROM dialogue_lines WHERE course_id = ? ORDER BY line_order ASC',
      variables: [Variable.withString(courseId)],
    ).get();

    final linesByDialogue = <String, List<DialogueLineModel>>{};
    for (final lr in lRows) {
      final did = lr.read<String>('dialogue_id');
      linesByDialogue
          .putIfAbsent(did, () => <DialogueLineModel>[])
          .add(DialogueLineModel.fromJson(lr.data));
    }

    return dRows.map((dr) {
      final did = dr.read<String>('id');
      return DialogueModel.fromJson(
        dr.data,
        linesByDialogue[did] ?? const <DialogueLineModel>[],
      );
    }).toList();
  }

  @override
  Future<List<JawiLetterModel>> getLetters(String courseId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM letters WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
      variables: [Variable.withString(courseId)],
    ).get();
    return rows.map((r) => JawiLetterModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<ArticleModel>> getArticles(String courseId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM articles WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
      variables: [Variable.withString(courseId)],
    ).get();
    return rows.map((r) => ArticleModel.fromJson(r.data)).toList();
  }

  @override
  Future<ArticleModel?> getArticle(String articleId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM articles WHERE id = ? LIMIT 1',
      variables: [Variable.withString(articleId)],
    ).get();
    if (rows.isEmpty) return null;
    return ArticleModel.fromJson(rows.first.data);
  }

  @override
  Future<List<CollectionCardModel>> getCollectionCards(String courseId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM collection_cards WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
      variables: [Variable.withString(courseId)],
    ).get();
    return rows.map((r) => CollectionCardModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<QuizBankItemModel>> getQuizBank(
    String courseId, {
    String? lessonId,
    bool includeUnverified = false,
  }) async {
    await db.ensureInitialized();
    final rows = lessonId != null
        ? await db.customSelect(
            'SELECT * FROM quiz_bank WHERE course_id = ? AND lesson_id = ? AND deprecated = 0 ORDER BY id ASC',
            variables: [
              Variable.withString(courseId),
              Variable.withString(lessonId),
            ],
          ).get()
        : await db.customSelect(
            'SELECT * FROM quiz_bank WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
            variables: [Variable.withString(courseId)],
          ).get();

    final items = rows.map((r) => QuizBankItemModel.fromJson(r.data)).toList();
    if (includeUnverified) return items;
    // Bagian 5.5 poin 4 & Bagian 14: saring soal needs_verification di mode normal.
    return items.where((q) => !q.needsVerification).toList();
  }

  @override
  Future<GameConfig> getGameConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;
    try {
      final raw = await _loadAsset('assets/content/game_config.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cachedConfig = GameConfig.fromJson(json);
      return _cachedConfig!;
    } catch (_) {
      _cachedConfig = const GameConfig();
      return _cachedConfig!;
    }
  }

  @override
  Future<List<AchievementModel>> getAchievements({
    Set<String> unlockedIds = const {},
  }) async {
    try {
      final raw = await _loadAsset('assets/content/achievements.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['achievements'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final now = DateTime.now();
      return list
          .map((item) => AchievementModel.fromJson(
                item,
                unlockedAt: unlockedIds.contains(item['id']) ? now : null,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
