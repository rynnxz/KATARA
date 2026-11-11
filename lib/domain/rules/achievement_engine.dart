class AchievementContext {
  const AchievementContext({
    required this.completedLessonsCount,
    required this.streakCurrent,
    required this.masteredGreetingCount,
    required this.masteredQuestionWordsCount,
    required this.totalQuestionWordsCount,
    required this.foodUnitCompletedPerfectly,
    required this.jawiWordsReadCount,
    required this.collectedCardsCount,
    required this.totalCardsCount,
    required this.perfectLessonsCount,
    required this.alreadyUnlockedIds,
  });

  final int completedLessonsCount;
  final int streakCurrent;
  final int masteredGreetingCount;
  final int masteredQuestionWordsCount;
  final int totalQuestionWordsCount;
  final bool foodUnitCompletedPerfectly;
  final int jawiWordsReadCount;
  final int collectedCardsCount;
  final int totalCardsCount;
  final int perfectLessonsCount;
  final Set<String> alreadyUnlockedIds;
}

class AchievementEngine {
  const AchievementEngine._();

  static List<String> evaluateNewlyUnlocked(AchievementContext ctx) {
    final newlyUnlocked = <String>[];

    void check(String id, bool condition) {
      if (condition && !ctx.alreadyUnlockedIds.contains(id)) {
        newlyUnlocked.add(id);
      }
    }

    // a01: Langkah Pertama (Selesaikan pelajaran pertama)
    check('a01', ctx.completedLessonsCount >= 1);
    // a02: Api Kecil (Streak 3 hari)
    check('a02', ctx.streakCurrent >= 3);
    // a03: Api Besar (Streak 30 hari)
    check('a03', ctx.streakCurrent >= 30);
    // a04: Penyapa (Pelajari sapaan / frasa sapaan)
    check('a04', ctx.masteredGreetingCount >= 6);
    // a05: Tukang Tanya (Kuasai semua kata tanya)
    check(
      'a05',
      ctx.totalQuestionWordsCount > 0 &&
          ctx.masteredQuestionWordsCount >= ctx.totalQuestionWordsCount,
    );
    // a06: Si Lemak (Selesaikan unit makanan tanpa salah)
    check('a06', ctx.foodUnitCompletedPerfectly);
    // a07: Pembaca Jawi
    check('a07', ctx.jawiWordsReadCount >= 6);
    // a08: Penjelajah Budaya / Istana
    check('a08', ctx.totalCardsCount > 0 && ctx.collectedCardsCount >= 1);
    // a10: Sempurna (10x pelajaran tanpa salah)
    check('a10', ctx.perfectLessonsCount >= 10);

    return newlyUnlocked;
  }
}
