import 'package:flutter_test/flutter_test.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/domain/rules/achievement_engine.dart';
import 'package:katara/domain/rules/gamification_rules.dart';

void main() {
  group('XP & Level Rules (Bagian 12.1)', () {
    test('xpToNext follows 50 * level formula and levelFromTotalXp handles multi-level jumps', () {
      expect(GamificationRules.xpToNext(1), 50);
      expect(GamificationRules.xpToNext(2), 100);
      expect(GamificationRules.xpToNext(3), 150);

      expect(GamificationRules.levelFromTotalXp(0), 1);
      expect(GamificationRules.levelFromTotalXp(49), 1);
      expect(GamificationRules.levelFromTotalXp(50), 2);
      expect(GamificationRules.levelFromTotalXp(149), 2);
      expect(GamificationRules.levelFromTotalXp(150), 3);
      // Lompat beberapa level sekaligus (50 + 100 + 150 = 300 -> Lv 4)
      expect(GamificationRules.levelFromTotalXp(300), 4);
    });

    test('titleForLevel maps levels to Melayu titles accurately', () {
      expect(GamificationRules.titleForLevel(1), 'Perantau');
      expect(GamificationRules.titleForLevel(4), 'Perantau');
      expect(GamificationRules.titleForLevel(5), 'Anak Pekan');
      expect(GamificationRules.titleForLevel(10), 'Penutur Muda');
      expect(GamificationRules.titleForLevel(15), 'Pandai Pantun');
      expect(GamificationRules.titleForLevel(20), 'Orang Kaya');
      expect(GamificationRules.titleForLevel(30), 'Datuk Bahasa');
    });

    test('calculateLessonXp awards base + perfect bonus + combo bonus up to max', () {
      const config = GameConfig();
      expect(
        GamificationRules.calculateLessonXp(
          lessonKind: 'vocab',
          wrongCount: 0,
          maxCombo: 10,
          config: config,
        ),
        10 + 5 + 2,
      );
      expect(
        GamificationRules.calculateLessonXp(
          lessonKind: 'boss',
          wrongCount: 1,
          maxCombo: 30,
          config: config,
        ),
        25 + 0 + 5,
      );
    });
  });

  group('Streak Rules (Bagian 12.2)', () {
    test('continues streak across consecutive days, consumes streak freeze automatically if 1 day missed, resets if freeze insufficient', () {
      // Kemarin belajar, hari ini selesai pelajaran -> streak naik
      final s1 = GamificationRules.applyStreakOnLessonComplete(
        streakCurrent: 3,
        streakBest: 3,
        streakFreezes: 1,
        lastActiveDate: '2026-10-31',
        todayDate: '2026-11-01',
      );
      expect(s1.streakCurrent, 4);
      expect(s1.streakBest, 4);
      expect(s1.incremented, isTrue);

      // Belajar dua kali di hari yang sama -> streak tidak bertambah dua kali
      final sSameDay = GamificationRules.applyStreakOnLessonComplete(
        streakCurrent: 4,
        streakBest: 4,
        streakFreezes: 1,
        lastActiveDate: '2026-11-01',
        todayDate: '2026-11-01',
      );
      expect(sSameDay.streakCurrent, 4);
      expect(sSameDay.incremented, isFalse);

      // Lewat 1 hari penuh (terakhir 2026-10-30, dibuka 2026-11-01) dengan 1 streak freeze -> pakai freeze otomatis
      final frozen = GamificationRules.reconcileStreakOnOpen(
        streakCurrent: 5,
        streakFreezes: 1,
        lastActiveDate: '2026-10-30',
        todayDate: '2026-11-01',
      );
      expect(frozen.streakCurrent, 5);
      expect(frozen.streakFreezes, 0);
      expect(frozen.lastActiveDate, '2026-10-31');

      // Lewat 2 hari penuh tanpa cukup freeze -> reset ke 0
      final reset = GamificationRules.reconcileStreakOnOpen(
        streakCurrent: 5,
        streakFreezes: 0,
        lastActiveDate: '2026-10-29',
        todayDate: '2026-11-01',
      );
      expect(reset.streakCurrent, 0);
    });
  });

  group('Hearts Regen & Level 1 Rule (Bagian 12.3)', () {
    test('hearts are disabled at Level 1 and enabled from Level 2 unless casualMode is true', () {
      const config = GameConfig();
      final now = DateTime(2026, 11, 1, 12, 0);
      final lv1User = UserStats(
        xpTotal: 0,
        level: 1,
        coins: 20,
        hearts: 5,
        heartsUpdatedAt: now,
        streakCurrent: 0,
        streakBest: 0,
        lastActiveDate: null,
        streakFreezes: 1,
        dailyGoalMinutes: 10,
        activeCourseId: 'ms-deli',
        updatedAt: now,
      );
      expect(lv1User.isHeartsEnabled(config), isFalse);

      final lv2User = lv1User.copyWith(level: 2);
      expect(lv2User.isHeartsEnabled(config), isTrue);

      final lv2Casual = lv2User.copyWith(casualMode: true);
      expect(lv2Casual.isHeartsEnabled(config), isFalse);
    });

    test('regenerateHearts recovers 1 heart per 30 minutes up to max 5', () {
      final t0 = DateTime(2026, 11, 1, 10, 0);
      final after25m = GamificationRules.regenerateHearts(
        currentHearts: 2,
        heartsUpdatedAt: t0,
        now: t0.add(const Duration(minutes: 25)),
      );
      expect(after25m.hearts, 2);

      final after65m = GamificationRules.regenerateHearts(
        currentHearts: 2,
        heartsUpdatedAt: t0,
        now: t0.add(const Duration(minutes: 65)),
      );
      expect(after65m.hearts, 4);
      expect(after65m.heartsUpdatedAt, t0.add(const Duration(minutes: 60)));
    });
  });

  group('Stars, SRS & AchievementEngine (Bagian 12.5 - 12.7)', () {
    test('calculateStars awards 3 stars for >=95%, 2 for >=80%, 1 otherwise', () {
      expect(GamificationRules.calculateStars(1.0), 3);
      expect(GamificationRules.calculateStars(0.95), 3);
      expect(GamificationRules.calculateStars(0.85), 2);
      expect(GamificationRules.calculateStars(0.60), 1);
    });

    test('updateWordMasterySrs follows [1, 1, 3, 7, 14, 30] day intervals and resets to 1 day on wrong', () {
      final now = DateTime(2026, 11, 1, 8, 0);
      final s1 = GamificationRules.updateWordMasterySrs(
        currentStrength: 0,
        isCorrect: true,
        now: now,
      );
      expect(s1.strength, 1);
      expect(s1.nextReviewAt, now.add(const Duration(days: 1)));

      final s2 = GamificationRules.updateWordMasterySrs(
        currentStrength: 1,
        isCorrect: true,
        now: now,
      );
      expect(s2.strength, 2);
      expect(s2.nextReviewAt, now.add(const Duration(days: 3)));

      final wrong = GamificationRules.updateWordMasterySrs(
        currentStrength: 4,
        isCorrect: false,
        now: now,
      );
      expect(wrong.strength, 3);
      expect(wrong.nextReviewAt, now.add(const Duration(days: 1)));
    });

    test('AchievementEngine unlocks expected badges', () {
      final unlocked = AchievementEngine.evaluateNewlyUnlocked(
        const AchievementContext(
          completedLessonsCount: 1,
          streakCurrent: 3,
          masteredGreetingCount: 6,
          masteredQuestionWordsCount: 7,
          totalQuestionWordsCount: 7,
          foodUnitCompletedPerfectly: true,
          jawiWordsReadCount: 0,
          collectedCardsCount: 1,
          totalCardsCount: 5,
          perfectLessonsCount: 1,
          alreadyUnlockedIds: {},
        ),
      );
      expect(unlocked, containsAll(['a01', 'a02', 'a04', 'a05', 'a06', 'a08']));
    });
  });
}
