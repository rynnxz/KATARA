import 'dart:math' as math;

import 'package:katara/domain/entities/user_progress.dart';

class GamificationRules {
  const GamificationRules._();

  /// `xpToNext(level) = 50 * level` (Bagian 12.1).
  static int xpToNext(int level, {int multiplier = 50}) {
    final safeLevel = math.max(1, level);
    return multiplier * safeLevel;
  }

  /// Total XP kumulatif minimum untuk mencapai `level`.
  static int cumulativeXpForLevel(int level, {int multiplier = 50}) {
    if (level <= 1) return 0;
    var sum = 0;
    for (var l = 1; l < level; l++) {
      sum += xpToNext(l, multiplier: multiplier);
    }
    return sum;
  }

  /// Menghitung level saat ini dari `xpTotal` (mendukung naik beberapa level sekaligus).
  static int levelFromTotalXp(int xpTotal, {int multiplier = 50}) {
    var level = 1;
    var remaining = math.max(0, xpTotal);
    while (remaining >= xpToNext(level, multiplier: multiplier)) {
      remaining -= xpToNext(level, multiplier: multiplier);
      level++;
    }
    return level;
  }

  /// Progres (0.0 - 1.0) menuju level berikutnya.
  static double levelProgress(int xpTotal, {int multiplier = 50}) {
    final level = levelFromTotalXp(xpTotal, multiplier: multiplier);
    final floorXp = cumulativeXpForLevel(level, multiplier: multiplier);
    final needed = xpToNext(level, multiplier: multiplier);
    if (needed <= 0) return 0.0;
    return ((xpTotal - floorXp) / needed).clamp(0.0, 1.0);
  }

  static double progressWithinCurrentLevel(int xpTotal) =>
      levelProgress(xpTotal);

  static int xpRequiredForNextLevel(int level) => xpToNext(level);

  static bool areHeartsEnabled({
    required int userLevel,
    required bool casualMode,
    required GameConfig config,
  }) {
    if (casualMode) return false;
    return userLevel >= config.heartsEnabledFromLevel;
  }

  /// Gelar berdasarkan level sesuai tabel Bagian 12.1.
  static String titleForLevel(int level) {
    if (level <= 4) return 'Perantau';
    if (level <= 9) return 'Anak Pekan';
    if (level <= 14) return 'Penutur Muda';
    if (level <= 19) return 'Pandai Pantun';
    if (level <= 29) return 'Orang Kaya';
    return 'Datuk Bahasa';
  }

  /// Hadiah koin saat naik dari `oldLevel` ke `newLevel` (mendukung multi-level up).
  static int levelUpRewardCoins(
    int oldLevel,
    int newLevel, {
    int coinsPerLevel = 5,
  }) {
    if (newLevel <= oldLevel) return 0;
    var totalCoins = 0;
    for (var lvl = oldLevel + 1; lvl <= newLevel; lvl++) {
      totalCoins += lvl * coinsPerLevel;
    }
    return totalCoins;
  }

  /// Menghitung XP pelajaran selesai (Bagian 12.1).
  static int calculateLessonXp({
    required String lessonKind,
    required int wrongCount,
    required int maxCombo,
    required GameConfig config,
  }) {
    final baseXp = switch (lessonKind) {
      'boss' => config.bossXp,
      'review' => config.reviewXp,
      _ => config.lessonCompleteXp,
    };
    final perfectBonus = wrongCount == 0 ? config.perfectBonusXp : 0;
    final comboBonus = math.min(
      config.comboBonusMax,
      (maxCombo ~/ config.comboStep) * config.comboBonusPerStep,
    );
    return baseXp + perfectBonus + comboBonus;
  }

  /// Menghitung bintang pelajaran: >=95% = 3, >=80% = 2, selesai = 1 (Bagian 12.6).
  static int calculateStars(double accuracy, {GameConfig? config}) {
    final threeMin = config?.threeStarsMinAccuracy ?? 0.95;
    final twoMin = config?.twoStarsMinAccuracy ?? 0.80;
    if (accuracy >= threeMin) return 3;
    if (accuracy >= twoMin) return 2;
    return 1;
  }

  /// Menghitung koin dari pelajaran selesai (3–5 koin berdasarkan bintang).
  static int calculateLessonCoins(int stars, {GameConfig? config}) {
    final minCoins = config?.lessonCoinsMin ?? 3;
    final maxCoins = config?.lessonCoinsMax ?? 5;
    return (minCoins + (stars - 1)).clamp(minCoins, maxCoins);
  }

  /// Format tanggal lokal `YYYY-MM-DD` (Bagian 12.2).
  static String formatLocalDate(DateTime localTime) {
    final y = localTime.year.toString().padLeft(4, '0');
    final m = localTime.month.toString().padLeft(2, '0');
    final d = localTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parseLocalDate(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Selisih hari kalender antara dua tanggal `YYYY-MM-DD`.
  static int calendarDaysBetween(String fromDate, String toDate) {
    final a = parseLocalDate(fromDate);
    final b = parseLocalDate(toDate);
    final utcA = DateTime.utc(a.year, a.month, a.day);
    final utcB = DateTime.utc(b.year, b.month, b.day);
    return utcB.difference(utcA).inDays;
  }

  /// Evaluasi streak saat aplikasi dibuka (termasuk pemakaian `streak_freezes` otomatis).
  static ({int streakCurrent, int streakFreezes, String? lastActiveDate})
  reconcileStreakOnOpen({
    required int streakCurrent,
    required int streakFreezes,
    required String? lastActiveDate,
    required String todayDate,
  }) {
    if (lastActiveDate == null || streakCurrent <= 0) {
      return (
        streakCurrent: 0,
        streakFreezes: streakFreezes,
        lastActiveDate: lastActiveDate,
      );
    }

    final diff = calendarDaysBetween(lastActiveDate, todayDate);
    if (diff <= 1) {
      // Belajar hari ini (0) atau kemarin (1): streak masih aman.
      return (
        streakCurrent: streakCurrent,
        streakFreezes: streakFreezes,
        lastActiveDate: lastActiveDate,
      );
    }

    final missedDays = diff - 1;
    if (streakFreezes >= missedDays) {
      // Gunakan streak freeze otomatis untuk menutup hari yang terlewat.
      final yesterday = parseLocalDate(todayDate)
          .subtract(const Duration(days: 1));
      return (
        streakCurrent: streakCurrent,
        streakFreezes: streakFreezes - missedDays,
        lastActiveDate: formatLocalDate(yesterday),
      );
    }

    return (
      streakCurrent: 0,
      streakFreezes: streakFreezes,
      lastActiveDate: lastActiveDate,
    );
  }

  /// Evaluasi streak saat pelajaran selesai hari ini.
  static ({
    int streakCurrent,
    int streakBest,
    int streakFreezes,
    String lastActiveDate,
    bool incremented,
  })
  applyStreakOnLessonComplete({
    required int streakCurrent,
    required int streakBest,
    required int streakFreezes,
    required String? lastActiveDate,
    required String todayDate,
  }) {
    final reconciled = reconcileStreakOnOpen(
      streakCurrent: streakCurrent,
      streakFreezes: streakFreezes,
      lastActiveDate: lastActiveDate,
      todayDate: todayDate,
    );

    if (reconciled.lastActiveDate == todayDate &&
        reconciled.streakCurrent > 0) {
      return (
        streakCurrent: reconciled.streakCurrent,
        streakBest: math.max(streakBest, reconciled.streakCurrent),
        streakFreezes: reconciled.streakFreezes,
        lastActiveDate: todayDate,
        incremented: false,
      );
    }

    final nextStreak = reconciled.streakCurrent + 1;
    final nextBest = math.max(streakBest, nextStreak);
    return (
      streakCurrent: nextStreak,
      streakBest: nextBest,
      streakFreezes: reconciled.streakFreezes,
      lastActiveDate: todayDate,
      incremented: true,
    );
  }

  /// Menghitung regenerasi nyawa (1 tiap 30 menit dari `heartsUpdatedAt` tanpa timer latar).
  static ({int hearts, DateTime heartsUpdatedAt}) regenerateHearts({
    required int currentHearts,
    required DateTime heartsUpdatedAt,
    required DateTime now,
    int maxHearts = 5,
    int regenMinutes = 30,
  }) {
    if (currentHearts >= maxHearts) {
      return (hearts: maxHearts, heartsUpdatedAt: now);
    }
    final elapsedMinutes = now.difference(heartsUpdatedAt).inMinutes;
    if (elapsedMinutes < regenMinutes) {
      return (hearts: currentHearts, heartsUpdatedAt: heartsUpdatedAt);
    }
    final recovered = elapsedMinutes ~/ regenMinutes;
    final nextHearts = math.min(maxHearts, currentHearts + recovered);
    final nextTimestamp = nextHearts >= maxHearts
        ? now
        : heartsUpdatedAt.add(Duration(minutes: recovered * regenMinutes));
    return (hearts: nextHearts, heartsUpdatedAt: nextTimestamp);
  }

  /// Spaced repetition sederhana (Bagian 12.7):
  /// benar -> strength + 1 (maks 5), salah -> strength - 1 (min 0, next_review_at = besok).
  static ({int strength, DateTime nextReviewAt}) updateWordMasterySrs({
    required int currentStrength,
    required bool isCorrect,
    required DateTime now,
    List<int> intervalsDays = const [1, 1, 3, 7, 14, 30],
  }) {
    if (!isCorrect) {
      final nextStrength = math.max(0, currentStrength - 1);
      return (
        strength: nextStrength,
        nextReviewAt: now.add(const Duration(days: 1)),
      );
    }
    final nextStrength = math.min(5, currentStrength + 1);
    final days = nextStrength < intervalsDays.length
        ? intervalsDays[nextStrength]
        : 30;
    return (
      strength: nextStrength,
      nextReviewAt: now.add(Duration(days: days)),
    );
  }
}
