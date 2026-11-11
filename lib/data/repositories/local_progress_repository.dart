import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/domain/repositories/content_repository.dart';
import 'package:katara/domain/repositories/progress_repository.dart';
import 'package:katara/domain/rules/achievement_engine.dart';
import 'package:katara/domain/rules/gamification_rules.dart';

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository({
    required this.db,
    required this.contentRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final ContentRepository contentRepository;
  final DateTime Function() _clock;
  static final _rng = math.Random();

  static String _generateId() {
    final t = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final r1 = _rng.nextInt(0x7FFFFFFF).toRadixString(16).padLeft(8, '0');
    final r2 = _rng.nextInt(0x7FFFFFFF).toRadixString(16).padLeft(8, '0');
    return '$t-$r1-$r2';
  }

  @override
  Stream<UserStats> watchStats() async* {
    yield await getStats();
    await for (final _ in db.tableChanges) {
      yield await getStats();
    }
  }

  @override
  Future<UserStats> getStats() async {
    await db.ensureInitialized();
    final config = await contentRepository.getGameConfig();
    final now = _clock();
    final todayStr = GamificationRules.formatLocalDate(now);

    final rows = await db
        .customSelect('SELECT * FROM user_stats WHERE id = 1 LIMIT 1')
        .get();
    if (rows.isEmpty) {
      return UserStats(
        xpTotal: 0,
        level: 1,
        coins: 20,
        hearts: config.maxHearts,
        heartsUpdatedAt: now,
        streakCurrent: 0,
        streakBest: 0,
        lastActiveDate: null,
        streakFreezes: 1,
        dailyGoalMinutes: 10,
        activeCourseId: null,
        updatedAt: now,
      );
    }

    final r = rows.first;
    final rawHearts = r.read<int>('hearts');
    final rawHeartsAt =
        DateTime.tryParse(r.read<String>('hearts_updated_at')) ?? now;
    final rawStreak = r.read<int>('streak_current');
    final rawFreezes = r.read<int>('streak_freezes');
    final rawLastDate = r.readNullable<String>('last_active_date');

    final regen = GamificationRules.regenerateHearts(
      currentHearts: rawHearts,
      heartsUpdatedAt: rawHeartsAt,
      now: now,
      maxHearts: config.maxHearts,
      regenMinutes: config.heartRegenMinutes,
    );

    final streakCheck = GamificationRules.reconcileStreakOnOpen(
      streakCurrent: rawStreak,
      streakFreezes: rawFreezes,
      lastActiveDate: rawLastDate,
      todayDate: todayStr,
    );

    if (regen.hearts != rawHearts ||
        streakCheck.streakCurrent != rawStreak ||
        streakCheck.streakFreezes != rawFreezes ||
        streakCheck.lastActiveDate != rawLastDate) {
      await db.customStatement(
        '''
        UPDATE user_stats SET
          hearts = ?,
          hearts_updated_at = ?,
          streak_current = ?,
          streak_freezes = ?,
          last_active_date = ?,
          updated_at = ?
        WHERE id = 1
        ''',
        [
          regen.hearts,
          regen.heartsUpdatedAt.toIso8601String(),
          streakCheck.streakCurrent,
          streakCheck.streakFreezes,
          streakCheck.lastActiveDate,
          now.toIso8601String(),
        ],
      );
    }

    return UserStats(
      xpTotal: r.read<int>('xp_total'),
      level: r.read<int>('level'),
      coins: r.read<int>('coins'),
      hearts: regen.hearts,
      heartsUpdatedAt: regen.heartsUpdatedAt,
      streakCurrent: streakCheck.streakCurrent,
      streakBest: r.read<int>('streak_best'),
      lastActiveDate: streakCheck.lastActiveDate,
      streakFreezes: streakCheck.streakFreezes,
      dailyGoalMinutes: r.read<int>('daily_goal_minutes'),
      activeCourseId: r.readNullable<String>('active_course_id'),
      displayName: r.read<String>('display_name'),
      learningGoal: r.read<String>('learning_goal'),
      casualMode: r.read<int>('casual_mode') == 1,
      onboardingCompleted: r.read<int>('onboarding_completed') == 1,
      updatedAt: DateTime.tryParse(r.read<String>('updated_at')) ?? now,
    );
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? learningGoal,
    int? dailyGoalMinutes,
    String? activeCourseId,
    bool? casualMode,
    bool? onboardingCompleted,
  }) async {
    final current = await getStats();
    final now = _clock();
    await db.customStatement(
      '''
      UPDATE user_stats SET
        display_name = ?,
        learning_goal = ?,
        daily_goal_minutes = ?,
        active_course_id = ?,
        casual_mode = ?,
        onboarding_completed = ?,
        updated_at = ?
      WHERE id = 1
      ''',
      [
        displayName ?? current.displayName,
        learningGoal ?? current.learningGoal,
        dailyGoalMinutes ?? current.dailyGoalMinutes,
        activeCourseId ?? current.activeCourseId,
        (casualMode ?? current.casualMode) ? 1 : 0,
        (onboardingCompleted ?? current.onboardingCompleted) ? 1 : 0,
        now.toIso8601String(),
      ],
    );
    db.notifyTableChanged('user_stats');
  }

  @override
  Future<Map<String, CourseProgress>> getCourseProgress(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM course_progress WHERE course_id = ?',
          variables: [Variable.withString(courseId)],
        )
        .get();

    final map = <String, CourseProgress>{};
    for (final r in rows) {
      final lid = r.read<String>('lesson_id');
      map[lid] = CourseProgress(
        courseId: r.read<String>('course_id'),
        lessonId: lid,
        stars: r.read<int>('stars'),
        bestScore: r.read<int>('best_score'),
        completedAt:
            DateTime.tryParse(r.read<String>('completed_at')) ?? _clock(),
      );
    }
    return map;
  }

  @override
  Stream<Map<String, CourseProgress>> watchCourseProgress(
    String courseId,
  ) async* {
    yield await getCourseProgress(courseId);
    await for (final _ in db.tableChanges) {
      yield await getCourseProgress(courseId);
    }
  }

  @override
  Future<LessonResult> completeLesson(LessonAttempt attempt) async {
    final config = await contentRepository.getGameConfig();
    final now = _clock();
    final todayStr = GamificationRules.formatLocalDate(now);
    final currentStats = await getStats();

    final xpEarned = GamificationRules.calculateLessonXp(
      lessonKind: attempt.lessonKind,
      wrongCount: attempt.wrongCount,
      maxCombo: attempt.maxCombo,
      config: config,
    );
    final starsEarned = GamificationRules.calculateStars(
      attempt.accuracy,
      config: config,
    );
    final accuracyPercent = (attempt.accuracy * 100).round();
    final lessonCoins = GamificationRules.calculateLessonCoins(
      starsEarned,
      config: config,
    );

    final newXpTotal = currentStats.xpTotal + xpEarned;
    final previousLevel = currentStats.level;
    final newLevel = GamificationRules.levelFromTotalXp(
      newXpTotal,
      multiplier: config.levelMultiplier,
    );
    final levelUpCoins = GamificationRules.levelUpRewardCoins(
      previousLevel,
      newLevel,
      coinsPerLevel: config.levelUpRewardCoinsPerLevel,
    );
    final totalCoinsEarned = lessonCoins + levelUpCoins;

    final streakUpdate = GamificationRules.applyStreakOnLessonComplete(
      streakCurrent: currentStats.streakCurrent,
      streakBest: currentStats.streakBest,
      streakFreezes: currentStats.streakFreezes,
      lastActiveDate: currentStats.lastActiveDate,
      todayDate: todayStr,
    );

    var newWordsCount = 0;
    final unlockedCards = <String>[];
    final newlyUnlockedAchievements = <String>[];

    await db.transaction(() async {
      // 1. Update course_progress (stars & best_score ambil nilai terbesar)
      final existingProg = await db
          .customSelect(
            'SELECT stars, best_score FROM course_progress WHERE course_id = ? AND lesson_id = ? LIMIT 1',
            variables: [
              Variable.withString(attempt.courseId),
              Variable.withString(attempt.lessonId),
            ],
          )
          .get();

      final bestStars = existingProg.isEmpty
          ? starsEarned
          : math.max(existingProg.first.read<int>('stars'), starsEarned);
      final bestScore = existingProg.isEmpty
          ? accuracyPercent
          : math.max(
              existingProg.first.read<int>('best_score'),
              accuracyPercent,
            );

      await db.customStatement(
        '''
        INSERT INTO course_progress (course_id, lesson_id, stars, best_score, completed_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(course_id, lesson_id) DO UPDATE SET
          stars = excluded.stars,
          best_score = excluded.best_score,
          completed_at = excluded.completed_at
        ''',
        [
          attempt.courseId,
          attempt.lessonId,
          bestStars,
          bestScore,
          now.toIso8601String(),
        ],
      );

      // 2. Update word_mastery (SRS Bagian 12.7)
      for (final outcome in attempt.itemOutcomes) {
        final existingMastery = await db
            .customSelect(
              'SELECT strength, correct_count, wrong_count FROM word_mastery WHERE course_id = ? AND item_id = ? LIMIT 1',
              variables: [
                Variable.withString(attempt.courseId),
                Variable.withString(outcome.itemId),
              ],
            )
            .get();

        if (existingMastery.isEmpty) {
          newWordsCount++;
        }

        final prevStrength = existingMastery.isEmpty
            ? 0
            : existingMastery.first.read<int>('strength');
        final prevCorrect = existingMastery.isEmpty
            ? 0
            : existingMastery.first.read<int>('correct_count');
        final prevWrong = existingMastery.isEmpty
            ? 0
            : existingMastery.first.read<int>('wrong_count');

        final srs = GamificationRules.updateWordMasterySrs(
          currentStrength: prevStrength,
          isCorrect: outcome.isCorrect,
          now: now,
          intervalsDays: config.srsIntervalsDays,
        );

        await db.customStatement(
          '''
          INSERT INTO word_mastery (
            course_id, item_id, item_type, strength,
            correct_count, wrong_count, last_seen_at, next_review_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(course_id, item_id) DO UPDATE SET
            strength = excluded.strength,
            correct_count = excluded.correct_count,
            wrong_count = excluded.wrong_count,
            last_seen_at = excluded.last_seen_at,
            next_review_at = excluded.next_review_at
          ''',
          [
            attempt.courseId,
            outcome.itemId,
            outcome.itemType,
            srs.strength,
            prevCorrect + (outcome.isCorrect ? 1 : 0),
            prevWrong + (outcome.isCorrect ? 0 : 1),
            now.toIso8601String(),
            srs.nextReviewAt.toIso8601String(),
          ],
        );
      }

      // 3. Cek kartu budaya yang terbuka saat unit selesai
      final unit = await contentRepository.getUnit(attempt.unitId);
      if (unit != null) {
        final progRows = await db
            .customSelect(
              'SELECT lesson_id FROM course_progress WHERE course_id = ? AND stars > 0',
              variables: [Variable.withString(attempt.courseId)],
            )
            .get();
        final completedLessonIds = progRows
            .map((r) => r.read<String>('lesson_id'))
            .toSet();
        final allUnitLessonsDone = unit.lessons.every(
          (l) => completedLessonIds.contains(l.id),
        );

        if (allUnitLessonsDone) {
          final cards = await contentRepository.getCollectionCards(
            attempt.courseId,
          );
          for (final card in cards) {
            if (card.unlockAfterUnitId == attempt.unitId) {
              await db.customStatement(
                '''
                INSERT OR IGNORE INTO collection_unlocked (course_id, card_id, unlocked_at)
                VALUES (?, ?, ?)
                ''',
                [attempt.courseId, card.id, now.toIso8601String()],
              );
              unlockedCards.add(card.id);
            }
          }
        }
      }

      // 4. Update user_stats & xp_log
      await db.customStatement(
        '''
        UPDATE user_stats SET
          xp_total = ?,
          level = ?,
          coins = coins + ?,
          streak_current = ?,
          streak_best = ?,
          streak_freezes = ?,
          last_active_date = ?,
          updated_at = ?
        WHERE id = 1
        ''',
        [
          newXpTotal,
          newLevel,
          totalCoinsEarned,
          streakUpdate.streakCurrent,
          streakUpdate.streakBest,
          streakUpdate.streakFreezes,
          streakUpdate.lastActiveDate,
          now.toIso8601String(),
        ],
      );

      await db.customStatement(
        '''
        INSERT INTO xp_log (date, course_id, amount, source)
        VALUES (?, ?, ?, ?)
        ''',
        [todayStr, attempt.courseId, xpEarned, 'lesson:${attempt.lessonId}'],
      );

      final eventId = _generateId();
      final nowIso = now.toIso8601String();
      await db.customStatement(
        '''
        INSERT INTO xp_events (event_id, course_id, amount, source, device_id, created_at, is_synced)
        VALUES (?, ?, ?, ?, 'local-device', ?, 0)
        ''',
        [
          eventId,
          attempt.courseId,
          xpEarned,
          'lesson:${attempt.lessonId}',
          nowIso,
        ],
      );

      await db.customStatement(
        '''
        INSERT INTO streak_history (date, course_id, xp_earned, lessons_completed, freeze_used, device_id, updated_at, is_synced)
        VALUES (?, ?, ?, 1, 0, 'local-device', ?, 0)
        ON CONFLICT(date) DO UPDATE SET
          xp_earned = streak_history.xp_earned + excluded.xp_earned,
          lessons_completed = streak_history.lessons_completed + 1,
          updated_at = excluded.updated_at,
          is_synced = 0
        ''',
        [todayStr, attempt.courseId, xpEarned, nowIso],
      );

      await db.customStatement(
        '''
        INSERT INTO sync_queue (operation_id, entity_type, entity_id, operation, payload_json, created_at)
        VALUES (?, 'dialect_progress', ?, 'upsert', ?, ?)
        ''',
        [
          _generateId(),
          '${attempt.courseId}_${attempt.lessonId}',
          jsonEncode({
            'course_id': attempt.courseId,
            'lesson_id': attempt.lessonId,
            'stars': bestStars,
            'best_score': bestScore,
            'completed_at': nowIso,
            'updated_at': nowIso,
          }),
          nowIso,
        ],
      );

      // 5. Update Daily Quests
      await _ensureDailyQuestsExistInTx(todayStr, config);
      await _incrementQuestMetricInTx(todayStr, 'lessons_done', 1);
      await _incrementQuestMetricInTx(todayStr, 'xp_today', xpEarned);
      if (attempt.maxCombo >= 10) {
        await _incrementQuestMetricInTx(
          todayStr,
          'correct_streak',
          attempt.maxCombo,
        );
      }
      if (attempt.jawiPracticedCount > 0 || attempt.lessonKind == 'jawi') {
        await _incrementQuestMetricInTx(
          todayStr,
          'jawi_practiced',
          math.max(1, attempt.jawiPracticedCount),
        );
      }

      // 6. Evaluasi Lencana (Achievements)
      final completedCountRow = await db
          .customSelect('SELECT COUNT(*) AS cnt FROM course_progress')
          .getSingle();
      final perfectCountRow = await db
          .customSelect(
            'SELECT COUNT(*) AS cnt FROM course_progress WHERE best_score = 100',
          )
          .getSingle();
      final unlockedRows = await db
          .customSelect('SELECT achievement_id FROM achievements_unlocked')
          .get();
      final alreadyUnlocked = unlockedRows
          .map((r) => r.read<String>('achievement_id'))
          .toSet();

      final masteredRows = await db
          .customSelect(
            'SELECT item_id FROM word_mastery WHERE course_id = ? AND strength >= 1',
            variables: [Variable.withString(attempt.courseId)],
          )
          .get();
      final masteredIds = masteredRows
          .map((r) => r.read<String>('item_id'))
          .toSet();

      final allWords = await contentRepository.getWords(attempt.courseId);
      final allPhrases = await contentRepository.getPhrases(attempt.courseId);
      final greetingItems = <String>{
        ...allWords.where((w) => w.category == 'sapaan').map((w) => w.id),
        ...allPhrases.where((p) => p.unitId.endsWith('0001')).map((p) => p.id),
      };
      final questionWordIds = allWords
          .where((w) => w.category == 'tanya')
          .map((w) => w.id)
          .toSet();

      final cardsUnlockedRow = await db
          .customSelect('SELECT COUNT(*) AS cnt FROM collection_unlocked')
          .getSingle();
      final allCards = await contentRepository.getCollectionCards(
        attempt.courseId,
      );

      final foodPerfect =
          attempt.unitId.endsWith('0004') &&
          attempt.wrongCount == 0 &&
          attempt.lessonKind == 'boss';

      final evaluated = AchievementEngine.evaluateNewlyUnlocked(
        AchievementContext(
          completedLessonsCount: completedCountRow.read<int>('cnt'),
          streakCurrent: streakUpdate.streakCurrent,
          masteredGreetingCount: greetingItems
              .where(masteredIds.contains)
              .length,
          masteredQuestionWordsCount: questionWordIds
              .where(masteredIds.contains)
              .length,
          totalQuestionWordsCount: questionWordIds.length,
          foodUnitCompletedPerfectly: foodPerfect,
          jawiWordsReadCount: attempt.jawiPracticedCount,
          collectedCardsCount: cardsUnlockedRow.read<int>('cnt'),
          totalCardsCount: allCards.length,
          perfectLessonsCount: perfectCountRow.read<int>('cnt'),
          alreadyUnlockedIds: alreadyUnlocked,
        ),
      );

      for (final achId in evaluated) {
        await db.customStatement(
          '''
          INSERT OR IGNORE INTO achievements_unlocked (achievement_id, unlocked_at)
          VALUES (?, ?)
          ''',
          [achId, now.toIso8601String()],
        );
        newlyUnlockedAchievements.add(achId);
      }
    });

    db.notifyTableChanged('user_stats');
    db.notifyTableChanged('course_progress');
    db.notifyTableChanged('word_mastery');

    return LessonResult(
      xpEarned: xpEarned,
      coinsEarned: totalCoinsEarned,
      starsEarned: starsEarned,
      accuracyPercent: accuracyPercent,
      previousLevel: previousLevel,
      newLevel: newLevel,
      newTitle: GamificationRules.titleForLevel(newLevel),
      streakCurrent: streakUpdate.streakCurrent,
      streakIncremented: streakUpdate.incremented,
      newWordsCount: newWordsCount,
      unlockedAchievements: newlyUnlockedAchievements,
      unlockedCardIds: unlockedCards,
    );
  }

  Future<void> _ensureDailyQuestsExistInTx(
    String todayStr,
    GameConfig config,
  ) async {
    final existing = await db
        .customSelect(
          'SELECT quest_id FROM daily_quests WHERE date = ?',
          variables: [Variable.withString(todayStr)],
        )
        .get();
    if (existing.isNotEmpty) return;

    final dailyPool = config.questsPool
        .where((q) => q.type == 'daily')
        .toList();
    if (dailyPool.isEmpty) return;

    // Pilih 3 misi harian secara deterministik berdasarkan tanggal hari ini.
    final seed = todayStr.codeUnits.fold<int>(0, (acc, c) => acc * 31 + c);
    final rng = math.Random(seed);
    final shuffled = List<QuestDefinition>.from(dailyPool)..shuffle(rng);
    final chosen = shuffled.take(3);

    for (final q in chosen) {
      await db.customStatement(
        '''
        INSERT OR IGNORE INTO daily_quests (date, quest_id, progress, target, claimed)
        VALUES (?, ?, 0, ?, 0)
        ''',
        [todayStr, q.id, q.target],
      );
    }
  }

  Future<void> _incrementQuestMetricInTx(
    String todayStr,
    String metric,
    int delta,
  ) async {
    final config = await contentRepository.getGameConfig();
    final matchingIds = config.questsPool
        .where((q) => q.metric == metric)
        .map((q) => q.id)
        .toList();
    for (final qid in matchingIds) {
      await db.customStatement(
        '''
        UPDATE daily_quests
        SET progress = MIN(target, progress + ?)
        WHERE date = ? AND quest_id = ?
        ''',
        [delta, todayStr, qid],
      );
    }
  }

  @override
  Future<List<WordMastery>> dueForReview(
    String courseId, {
    int limit = 20,
  }) async {
    await db.ensureInitialized();
    final nowIso = _clock().toIso8601String();
    final rows = await db
        .customSelect(
          '''
      SELECT * FROM word_mastery
      WHERE course_id = ? AND next_review_at <= ?
      ORDER BY next_review_at ASC, strength ASC
      LIMIT ?
      ''',
          variables: [
            Variable.withString(courseId),
            Variable.withString(nowIso),
            Variable.withInt(limit),
          ],
        )
        .get();

    return rows.map(_mapMastery).toList();
  }

  @override
  Future<List<WordMastery>> getCourseMastery(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM word_mastery WHERE course_id = ? ORDER BY last_seen_at DESC',
          variables: [Variable.withString(courseId)],
        )
        .get();
    return rows.map(_mapMastery).toList();
  }

  WordMastery _mapMastery(QueryRow r) => WordMastery(
    courseId: r.read<String>('course_id'),
    itemId: r.read<String>('item_id'),
    itemType: r.read<String>('item_type'),
    strength: r.read<int>('strength'),
    correctCount: r.read<int>('correct_count'),
    wrongCount: r.read<int>('wrong_count'),
    lastSeenAt: DateTime.tryParse(r.read<String>('last_seen_at')) ?? _clock(),
    nextReviewAt:
        DateTime.tryParse(r.read<String>('next_review_at')) ?? _clock(),
  );

  @override
  Future<void> recordPracticeReview({
    required String courseId,
    required List<ItemAttemptOutcome> outcomes,
    required int xpEarned,
  }) async {
    final config = await contentRepository.getGameConfig();
    final now = _clock();
    final todayStr = GamificationRules.formatLocalDate(now);
    final stats = await getStats();

    final newXp = stats.xpTotal + xpEarned;
    final newLevel = GamificationRules.levelFromTotalXp(
      newXp,
      multiplier: config.levelMultiplier,
    );

    await db.transaction(() async {
      for (final outcome in outcomes) {
        final existing = await db
            .customSelect(
              'SELECT strength, correct_count, wrong_count FROM word_mastery WHERE course_id = ? AND item_id = ? LIMIT 1',
              variables: [
                Variable.withString(courseId),
                Variable.withString(outcome.itemId),
              ],
            )
            .get();

        final prevStrength = existing.isEmpty
            ? 0
            : existing.first.read<int>('strength');
        final prevCorrect = existing.isEmpty
            ? 0
            : existing.first.read<int>('correct_count');
        final prevWrong = existing.isEmpty
            ? 0
            : existing.first.read<int>('wrong_count');

        final srs = GamificationRules.updateWordMasterySrs(
          currentStrength: prevStrength,
          isCorrect: outcome.isCorrect,
          now: now,
          intervalsDays: config.srsIntervalsDays,
        );

        await db.customStatement(
          '''
          INSERT INTO word_mastery (
            course_id, item_id, item_type, strength,
            correct_count, wrong_count, last_seen_at, next_review_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(course_id, item_id) DO UPDATE SET
            strength = excluded.strength,
            correct_count = excluded.correct_count,
            wrong_count = excluded.wrong_count,
            last_seen_at = excluded.last_seen_at,
            next_review_at = excluded.next_review_at
          ''',
          [
            courseId,
            outcome.itemId,
            outcome.itemType,
            srs.strength,
            prevCorrect + (outcome.isCorrect ? 1 : 0),
            prevWrong + (outcome.isCorrect ? 0 : 1),
            now.toIso8601String(),
            srs.nextReviewAt.toIso8601String(),
          ],
        );
      }

      await db.customStatement(
        'UPDATE user_stats SET xp_total = ?, level = ?, updated_at = ? WHERE id = 1',
        [newXp, newLevel, now.toIso8601String()],
      );

      await db.customStatement(
        'INSERT INTO xp_log (date, course_id, amount, source) VALUES (?, ?, ?, ?)',
        [todayStr, courseId, xpEarned, 'practice'],
      );

      final nowIso = now.toIso8601String();
      final eventId = _generateId();
      await db.customStatement(
        '''
        INSERT INTO xp_events (event_id, course_id, amount, source, device_id, created_at, is_synced)
        VALUES (?, ?, ?, 'practice', 'local-device', ?, 0)
        ''',
        [eventId, courseId, xpEarned, nowIso],
      );

      await db.customStatement(
        '''
        INSERT INTO sync_queue (operation_id, entity_type, entity_id, operation, payload_json, created_at)
        VALUES (?, 'xp_events', ?, 'upsert', ?, ?)
        ''',
        [
          _generateId(),
          eventId,
          jsonEncode({
            'event_id': eventId,
            'course_id': courseId,
            'delta_xp': xpEarned,
            'amount': xpEarned,
            'source_type': 'practice',
            'source': 'practice',
            'created_at': nowIso,
          }),
          nowIso,
        ],
      );
    });

    db.notifyTableChanged('user_stats');
    db.notifyTableChanged('word_mastery');
  }

  @override
  Future<List<DailyQuestProgress>> getDailyQuests() async {
    await db.ensureInitialized();
    final config = await contentRepository.getGameConfig();
    final todayStr = GamificationRules.formatLocalDate(_clock());

    await db.transaction(() async {
      await _ensureDailyQuestsExistInTx(todayStr, config);
    });

    final rows = await db
        .customSelect(
          'SELECT * FROM daily_quests WHERE date = ?',
          variables: [Variable.withString(todayStr)],
        )
        .get();

    final defById = {for (final q in config.questsPool) q.id: q};
    return rows.map((r) {
      final qid = r.read<String>('quest_id');
      final def = defById[qid];
      return DailyQuestProgress(
        date: r.read<String>('date'),
        questId: qid,
        title: def?.title ?? qid,
        type: def?.type ?? 'daily',
        metric: def?.metric ?? 'lessons_done',
        progress: r.read<int>('progress'),
        target: r.read<int>('target'),
        rewardCoins: def?.rewardCoins ?? 10,
        claimed: r.read<int>('claimed') == 1,
      );
    }).toList();
  }

  @override
  Future<int> claimQuestReward(String questId) async {
    final config = await contentRepository.getGameConfig();
    final todayStr = GamificationRules.formatLocalDate(_clock());
    final def = config.questsPool.where((q) => q.id == questId).firstOrNull;
    if (def == null) return 0;

    final rows = await db
        .customSelect(
          'SELECT progress, target, claimed FROM daily_quests WHERE date = ? AND quest_id = ? LIMIT 1',
          variables: [
            Variable.withString(todayStr),
            Variable.withString(questId),
          ],
        )
        .get();
    if (rows.isEmpty) return 0;
    final row = rows.first;
    if (row.read<int>('claimed') == 1 ||
        row.read<int>('progress') < row.read<int>('target')) {
      return 0;
    }

    await db.transaction(() async {
      await db.customStatement(
        'UPDATE daily_quests SET claimed = 1 WHERE date = ? AND quest_id = ?',
        [todayStr, questId],
      );
      await db.customStatement(
        'UPDATE user_stats SET coins = coins + ?, updated_at = ? WHERE id = 1',
        [def.rewardCoins, _clock().toIso8601String()],
      );
    });
    db.notifyTableChanged('user_stats');
    return def.rewardCoins;
  }

  @override
  Future<bool> isDailyChestClaimedToday() async {
    final todayStr = GamificationRules.formatLocalDate(_clock());
    final rows = await db
        .customSelect(
          'SELECT qty FROM inventory WHERE item_id = ? LIMIT 1',
          variables: [Variable.withString('chest:$todayStr')],
        )
        .get();
    return rows.isNotEmpty && rows.first.read<int>('qty') > 0;
  }

  @override
  Future<int?> claimDailyChest() async {
    if (await isDailyChestClaimedToday()) return null;
    final quests = await getDailyQuests();
    if (quests.isEmpty || !quests.every((q) => q.isCompleted)) return null;

    final config = await contentRepository.getGameConfig();
    final todayStr = GamificationRules.formatLocalDate(_clock());
    final seed = todayStr.codeUnits.fold<int>(17, (a, b) => a * 31 + b);
    final rng = math.Random(seed);
    final coinsReward =
        config.dailyChestCoinsMin +
        rng.nextInt(
          math.max(
            1,
            config.dailyChestCoinsMax - config.dailyChestCoinsMin + 1,
          ),
        );

    final stats = await getStats();
    final newXp = stats.xpTotal + config.dailyQuestsAllDoneXp;
    final newLevel = GamificationRules.levelFromTotalXp(
      newXp,
      multiplier: config.levelMultiplier,
    );

    await db.transaction(() async {
      await db.customStatement(
        'INSERT OR REPLACE INTO inventory (item_id, qty) VALUES (?, 1)',
        ['chest:$todayStr'],
      );
      await db.customStatement(
        'UPDATE user_stats SET coins = coins + ?, xp_total = ?, level = ?, updated_at = ? WHERE id = 1',
        [coinsReward, newXp, newLevel, _clock().toIso8601String()],
      );
    });
    db.notifyTableChanged('user_stats');
    return coinsReward;
  }

  @override
  Future<Set<String>> getUnlockedAchievements() async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect('SELECT achievement_id FROM achievements_unlocked')
        .get();
    return rows.map((r) => r.read<String>('achievement_id')).toSet();
  }

  @override
  Future<Set<String>> getUnlockedCards(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT card_id FROM collection_unlocked WHERE course_id = ?',
          variables: [Variable.withString(courseId)],
        )
        .get();
    return rows.map((r) => r.read<String>('card_id')).toSet();
  }

  @override
  Future<void> unlockArticleAndCard({
    required String courseId,
    required String articleId,
    String? cardId,
  }) async {
    final now = _clock();
    final todayStr = GamificationRules.formatLocalDate(now);
    final config = await contentRepository.getGameConfig();

    await db.transaction(() async {
      if (cardId != null) {
        await db.customStatement(
          '''
          INSERT OR IGNORE INTO collection_unlocked (course_id, card_id, unlocked_at)
          VALUES (?, ?, ?)
          ''',
          [courseId, cardId, now.toIso8601String()],
        );
      }
      await _ensureDailyQuestsExistInTx(todayStr, config);
      await _incrementQuestMetricInTx(todayStr, 'articles_read', 1);
    });
    db.notifyTableChanged('user_stats');
  }

  @override
  Future<Map<String, int>> getInventory() async {
    await db.ensureInitialized();
    final rows = await db.customSelect('SELECT * FROM inventory').get();
    return {
      for (final r in rows) r.read<String>('item_id'): r.read<int>('qty'),
    };
  }

  @override
  Future<bool> buyShopItem(ShopItemConfig item) async {
    final stats = await getStats();
    if (stats.coins < item.priceCoins) return false;
    final config = await contentRepository.getGameConfig();
    final now = _clock();

    await db.transaction(() async {
      await db.customStatement(
        'UPDATE user_stats SET coins = coins - ?, updated_at = ? WHERE id = 1',
        [item.priceCoins, now.toIso8601String()],
      );

      if (item.id == 'i01') {
        // Streak freeze
        await db.customStatement(
          'UPDATE user_stats SET streak_freezes = streak_freezes + 1 WHERE id = 1',
        );
      } else if (item.id == 'i02') {
        // Isi nyawa penuh
        await db.customStatement(
          'UPDATE user_stats SET hearts = ?, hearts_updated_at = ? WHERE id = 1',
          [config.maxHearts, now.toIso8601String()],
        );
      }

      await db.customStatement(
        '''
        INSERT INTO inventory (item_id, qty) VALUES (?, 1)
        ON CONFLICT(item_id) DO UPDATE SET qty = qty + 1
        ''',
        [item.id],
      );
    });

    db.notifyTableChanged('user_stats');
    return true;
  }

  @override
  Future<bool> spendHeart() async {
    final stats = await getStats();
    final config = await contentRepository.getGameConfig();
    if (!stats.isHeartsEnabled(config)) {
      return true;
    }
    if (stats.hearts <= 0) return false;

    final now = _clock();
    await db.customStatement(
      '''
      UPDATE user_stats SET
        hearts = MAX(0, hearts - 1),
        hearts_updated_at = CASE WHEN hearts = ? THEN ? ELSE hearts_updated_at END,
        updated_at = ?
      WHERE id = 1
      ''',
      [config.maxHearts, now.toIso8601String(), now.toIso8601String()],
    );
    db.notifyTableChanged('user_stats');
    return true;
  }

  @override
  Future<Map<String, int>> getWeeklyXpByDate({int days = 7}) async {
    await db.ensureInitialized();
    final now = _clock();
    final result = <String, int>{};
    for (var i = days - 1; i >= 0; i--) {
      final d = GamificationRules.formatLocalDate(
        now.subtract(Duration(days: i)),
      );
      result[d] = 0;
    }

    final rows = await db
        .customSelect(
          'SELECT date, SUM(amount) AS total FROM xp_log GROUP BY date',
        )
        .get();
    for (final r in rows) {
      final d = r.read<String>('date');
      if (result.containsKey(d)) {
        result[d] = r.read<int>('total');
      }
    }
    return result;
  }

  @override
  Future<Set<String>> getActiveDatesHistory() async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect('SELECT DISTINCT date FROM xp_log')
        .get();
    final set = rows.map((r) => r.read<String>('date')).toSet();
    final stats = await getStats();
    if (stats.lastActiveDate != null) {
      set.add(stats.lastActiveDate!);
    }
    return set;
  }

  @override
  Future<void> submitReport({
    required String courseId,
    required String itemId,
    required String itemType,
    required String reason,
    String? note,
  }) async {
    await db.ensureInitialized();
    await db.customStatement(
      '''
      INSERT INTO reports (course_id, item_id, item_type, reason, note, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [courseId, itemId, itemType, reason, note, _clock().toIso8601String()],
    );
  }

  @override
  Future<void> resetAllUserData() async {
    await db.ensureInitialized();
    final nowIso = _clock().toIso8601String();
    await db.transaction(() async {
      for (final table in const [
        'course_progress',
        'word_mastery',
        'daily_quests',
        'achievements_unlocked',
        'collection_unlocked',
        'inventory',
        'xp_log',
        'pending_sync',
        'reports',
      ]) {
        await db.customStatement('DELETE FROM $table');
      }
      await db.customStatement(
        '''
        UPDATE user_stats SET
          xp_total = 0,
          level = 1,
          coins = 20,
          hearts = 5,
          hearts_updated_at = ?,
          streak_current = 0,
          streak_best = 0,
          last_active_date = NULL,
          streak_freezes = 1,
          daily_goal_minutes = 10,
          active_course_id = NULL,
          display_name = 'Pelajar',
          learning_goal = 'budaya',
          casual_mode = 0,
          onboarding_completed = 0,
          updated_at = ?
        WHERE id = 1
        ''',
        [nowIso, nowIso],
      );
    });
    db.notifyTableChanged('user_stats');
  }
}
