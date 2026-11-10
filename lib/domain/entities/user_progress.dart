class GameConfig {
  const GameConfig({
    this.lessonCompleteXp = 10,
    this.perfectBonusXp = 5,
    this.comboStep = 5,
    this.comboBonusPerStep = 1,
    this.comboBonusMax = 5,
    this.reviewXp = 8,
    this.bossXp = 25,
    this.dailyQuestsAllDoneXp = 20,
    this.levelMultiplier = 50,
    this.levelUpRewardCoinsPerLevel = 5,
    this.maxHearts = 5,
    this.heartRegenMinutes = 30,
    this.heartsEnabledFromLevel = 2,
    this.lessonCoinsMin = 3,
    this.lessonCoinsMax = 5,
    this.dailyChestCoinsMin = 15,
    this.dailyChestCoinsMax = 30,
    this.threeStarsMinAccuracy = 0.95,
    this.twoStarsMinAccuracy = 0.80,
    this.srsIntervalsDays = const [1, 1, 3, 7, 14, 30],
    this.shopItems = const [],
    this.questsPool = const [],
  });

  final int lessonCompleteXp;
  final int perfectBonusXp;
  final int comboStep;
  final int comboBonusPerStep;
  final int comboBonusMax;
  final int reviewXp;
  final int bossXp;
  final int dailyQuestsAllDoneXp;
  final int levelMultiplier;
  final int levelUpRewardCoinsPerLevel;
  final int maxHearts;
  final int heartRegenMinutes;
  final int heartsEnabledFromLevel;
  final int lessonCoinsMin;
  final int lessonCoinsMax;
  final int dailyChestCoinsMin;
  final int dailyChestCoinsMax;
  final double threeStarsMinAccuracy;
  final double twoStarsMinAccuracy;
  final List<int> srsIntervalsDays;
  final List<ShopItemConfig> shopItems;
  final List<QuestDefinition> questsPool;

  int get heartsMax => maxHearts;

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    final xp = json['xp'] as Map<String, dynamic>? ?? const {};
    final hearts = json['hearts'] as Map<String, dynamic>? ?? const {};
    final coins = json['coins'] as Map<String, dynamic>? ?? const {};
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    final srs = json['srs'] as Map<String, dynamic>? ?? const {};
    final rawIntervals =
        (srs['intervals_days_by_strength'] as List<dynamic>?) ??
            const [1, 1, 3, 7, 14, 30];
    final rawShop = (json['shop_items'] as List<dynamic>?) ?? const [];
    final rawQuests = (json['quests_pool'] as List<dynamic>?) ?? const [];

    return GameConfig(
      lessonCompleteXp: (xp['lesson_complete'] as num?)?.toInt() ?? 10,
      perfectBonusXp: (xp['perfect_bonus'] as num?)?.toInt() ?? 5,
      comboStep: (xp['combo_step'] as num?)?.toInt() ?? 5,
      comboBonusPerStep: (xp['combo_bonus_per_step'] as num?)?.toInt() ?? 1,
      comboBonusMax: (xp['combo_bonus_max'] as num?)?.toInt() ?? 5,
      reviewXp: (xp['review_xp'] as num?)?.toInt() ?? 8,
      bossXp: (xp['boss_xp'] as num?)?.toInt() ?? 25,
      dailyQuestsAllDoneXp:
          (xp['daily_quests_all_done_xp'] as num?)?.toInt() ?? 20,
      levelMultiplier: (xp['level_multiplier'] as num?)?.toInt() ?? 50,
      levelUpRewardCoinsPerLevel:
          (json['level_up_reward_coins_per_level'] as num?)?.toInt() ?? 5,
      maxHearts: (hearts['max'] as num?)?.toInt() ?? 5,
      heartRegenMinutes: (hearts['regen_minutes'] as num?)?.toInt() ?? 30,
      heartsEnabledFromLevel:
          (hearts['hearts_enabled_from_level'] as num?)?.toInt() ?? 2,
      lessonCoinsMin: (coins['lesson_min'] as num?)?.toInt() ?? 3,
      lessonCoinsMax: (coins['lesson_max'] as num?)?.toInt() ?? 5,
      dailyChestCoinsMin: (coins['daily_chest_min'] as num?)?.toInt() ?? 15,
      dailyChestCoinsMax: (coins['daily_chest_max'] as num?)?.toInt() ?? 30,
      threeStarsMinAccuracy:
          (stars['three_stars_min_accuracy'] as num?)?.toDouble() ?? 0.95,
      twoStarsMinAccuracy:
          (stars['two_stars_min_accuracy'] as num?)?.toDouble() ?? 0.80,
      srsIntervalsDays: rawIntervals.map((e) => (e as num).toInt()).toList(),
      shopItems: rawShop
          .map((e) => ShopItemConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      questsPool: rawQuests
          .map((e) => QuestDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShopItemConfig {
  const ShopItemConfig({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCoins,
    this.description = '',
    this.maxOwned,
  });

  final String id;
  final String name;
  final String category;
  final int priceCoins;
  final String description;
  final int? maxOwned;

  factory ShopItemConfig.fromJson(Map<String, dynamic> json) => ShopItemConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'umum',
        priceCoins: (json['price_coins'] as num?)?.toInt() ?? 50,
        description: json['description'] as String? ??
            'Item pendukung belajar di Kedai Si Rebung.',
        maxOwned: (json['max_owned'] as num?)?.toInt(),
      );
}

class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.target,
    required this.metric,
    required this.rewardCoins,
  });

  final String id;
  final String type;
  final String title;
  final int target;
  final String metric;
  final int rewardCoins;

  factory QuestDefinition.fromJson(Map<String, dynamic> json) =>
      QuestDefinition(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'daily',
        title: json['title'] as String,
        target: (json['target'] as num?)?.toInt() ?? 1,
        metric: json['metric'] as String? ?? 'lessons_done',
        rewardCoins: (json['reward_coins'] as num?)?.toInt() ?? 10,
      );
}

class UserStats {
  const UserStats({
    required this.xpTotal,
    required this.level,
    required this.coins,
    required this.hearts,
    required this.heartsUpdatedAt,
    required this.streakCurrent,
    required this.streakBest,
    required this.lastActiveDate,
    required this.streakFreezes,
    required this.dailyGoalMinutes,
    required this.activeCourseId,
    required this.updatedAt,
    this.displayName = 'Pelajar',
    this.learningGoal = 'budaya',
    this.casualMode = false,
    this.onboardingCompleted = false,
  });

  final int xpTotal;
  final int level;
  final int coins;
  final int hearts;
  final DateTime heartsUpdatedAt;
  final int streakCurrent;
  final int streakBest;
  final String? lastActiveDate;
  final int streakFreezes;
  final int dailyGoalMinutes;
  final String? activeCourseId;
  final String displayName;
  final String learningGoal;
  final bool casualMode;
  final bool onboardingCompleted;
  final DateTime updatedAt;

  bool isHeartsEnabled(GameConfig config) {
    if (casualMode) return false;
    return level >= config.heartsEnabledFromLevel;
  }

  UserStats copyWith({
    int? xpTotal,
    int? level,
    int? coins,
    int? hearts,
    DateTime? heartsUpdatedAt,
    int? streakCurrent,
    int? streakBest,
    String? lastActiveDate,
    int? streakFreezes,
    int? dailyGoalMinutes,
    String? activeCourseId,
    String? displayName,
    String? learningGoal,
    bool? casualMode,
    bool? onboardingCompleted,
    DateTime? updatedAt,
  }) {
    return UserStats(
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      hearts: hearts ?? this.hearts,
      heartsUpdatedAt: heartsUpdatedAt ?? this.heartsUpdatedAt,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakBest: streakBest ?? this.streakBest,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      activeCourseId: activeCourseId ?? this.activeCourseId,
      displayName: displayName ?? this.displayName,
      learningGoal: learningGoal ?? this.learningGoal,
      casualMode: casualMode ?? this.casualMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CourseProgress {
  const CourseProgress({
    required this.courseId,
    required this.lessonId,
    required this.stars,
    required this.bestScore,
    required this.completedAt,
  });

  final String courseId;
  final String lessonId;
  final int stars;
  final int bestScore;
  final DateTime completedAt;
}

class WordMastery {
  const WordMastery({
    required this.courseId,
    required this.itemId,
    required this.itemType,
    required this.strength,
    required this.correctCount,
    required this.wrongCount,
    required this.lastSeenAt,
    required this.nextReviewAt,
  });

  final String courseId;
  final String itemId;
  final String itemType;
  final int strength;
  final int correctCount;
  final int wrongCount;
  final DateTime lastSeenAt;
  final DateTime nextReviewAt;
}

class ItemAttemptOutcome {
  const ItemAttemptOutcome({
    required this.itemId,
    required this.itemType,
    required this.isCorrect,
  });

  final String itemId;
  final String itemType;
  final bool isCorrect;
}

class LessonAttempt {
  const LessonAttempt({
    required this.courseId,
    required this.lessonId,
    required this.unitId,
    required this.lessonKind,
    required this.totalQuestions,
    required this.correctFirstTryCount,
    required this.wrongCount,
    required this.maxCombo,
    required this.itemOutcomes,
    this.jawiPracticedCount = 0,
  });

  final String courseId;
  final String lessonId;
  final String unitId;
  final String lessonKind;
  final int totalQuestions;
  final int correctFirstTryCount;
  final int wrongCount;
  final int maxCombo;
  final List<ItemAttemptOutcome> itemOutcomes;
  final int jawiPracticedCount;

  double get accuracy => totalQuestions <= 0
      ? 1.0
      : (correctFirstTryCount / totalQuestions).clamp(0.0, 1.0);
}

class LessonResult {
  const LessonResult({
    required this.xpEarned,
    required this.coinsEarned,
    required this.starsEarned,
    required this.accuracyPercent,
    required this.previousLevel,
    required this.newLevel,
    required this.newTitle,
    required this.streakCurrent,
    required this.streakIncremented,
    required this.newWordsCount,
    required this.unlockedAchievements,
    required this.unlockedCardIds,
  });

  final int xpEarned;
  final int coinsEarned;
  final int starsEarned;
  final int accuracyPercent;
  final int previousLevel;
  final int newLevel;
  final String newTitle;
  final int streakCurrent;
  final bool streakIncremented;
  final int newWordsCount;
  final List<String> unlockedAchievements;
  final List<String> unlockedCardIds;

  bool get leveledUp => newLevel > previousLevel;
  int get stars => starsEarned;
  double get accuracy => (accuracyPercent / 100.0).clamp(0.0, 1.0);
  int get newStreak => streakCurrent;
  List<String> get newlyUnlockedAchievements => unlockedAchievements;
  int get levelUpCoinsReward => leveledUp ? newLevel * 5 : 0;
}

class DailyQuestProgress {
  const DailyQuestProgress({
    required this.date,
    required this.questId,
    required this.title,
    required this.type,
    required this.metric,
    required this.progress,
    required this.target,
    required this.rewardCoins,
    required this.claimed,
  });

  final String date;
  final String questId;
  final String title;
  final String type;
  final String metric;
  final int progress;
  final int target;
  final int rewardCoins;
  final bool claimed;

  bool get isCompleted => progress >= target;
  double get ratio => target <= 0 ? 1.0 : (progress / target).clamp(0.0, 1.0);
}

class AchievementModel {
  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.activeMvp,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final bool activeMvp;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;
  bool get unlocked => isUnlocked;
  String get title => name;
  int get rewardCoins => 15;

  factory AchievementModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? unlockedAt,
  }) =>
      AchievementModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        activeMvp: json['active_mvp'] == true || json['active_mvp'] == 1,
        unlockedAt: unlockedAt,
      );
}

enum SyncState {
  synced,
  syncing,
  offline,
  failed,
  pending,
}

class SyncStatusSummary {
  const SyncStatusSummary({
    required this.state,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.userEmail,
    this.displayName,
    this.isAnonymous = true,
  });

  final SyncState state;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final String? userEmail;
  final String? displayName;
  final bool isAnonymous;

  bool get isSignedInWithGoogle => !isAnonymous && userEmail != null;
}

class XpEventModel {
  const XpEventModel({
    required this.eventId,
    required this.courseId,
    required this.amount,
    required this.source,
    required this.deviceId,
    required this.createdAt,
    this.isSynced = false,
  });

  final String eventId;
  final String courseId;
  final int amount;
  final String source;
  final String deviceId;
  final DateTime createdAt;
  final bool isSynced;

  factory XpEventModel.fromJson(Map<String, dynamic> json) => XpEventModel(
        eventId: json['event_id'] as String,
        courseId: json['course_id'] as String? ?? 'ms-deli',
        amount: (json['amount'] as num).toInt(),
        source: json['source'] as String? ?? 'lesson',
        deviceId: json['device_id'] as String? ?? 'local-device',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now().toUtc(),
        isSynced: json['is_synced'] == true || json['is_synced'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'course_id': courseId,
        'amount': amount,
        'source': source,
        'device_id': deviceId,
        'created_at': createdAt.toIso8601String(),
        'is_synced': isSynced,
      };
}

class StreakHistoryEntry {
  const StreakHistoryEntry({
    required this.date,
    required this.courseId,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.updatedAt,
    this.freezeUsed = false,
    this.deviceId = 'local-device',
    this.isSynced = false,
  });

  final String date;
  final String courseId;
  final int xpEarned;
  final int lessonsCompleted;
  final bool freezeUsed;
  final String deviceId;
  final DateTime updatedAt;
  final bool isSynced;

  factory StreakHistoryEntry.fromJson(Map<String, dynamic> json) =>
      StreakHistoryEntry(
        date: json['date'] as String,
        courseId: json['course_id'] as String? ?? 'ms-deli',
        xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
        lessonsCompleted: (json['lessons_completed'] as num?)?.toInt() ?? 0,
        freezeUsed: json['freeze_used'] == true || json['freeze_used'] == 1,
        deviceId: json['device_id'] as String? ?? 'local-device',
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now().toUtc(),
        isSynced: json['is_synced'] == true || json['is_synced'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'course_id': courseId,
        'xp_earned': xpEarned,
        'lessons_completed': lessonsCompleted,
        'freeze_used': freezeUsed,
        'device_id': deviceId,
        'updated_at': updatedAt.toIso8601String(),
        'is_synced': isSynced,
      };
}

class SyncQueueItemModel {
  const SyncQueueItemModel({
    required this.id,
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastError,
  });

  final int id;
  final String operationId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;
}

class DialectMasterySummary {
  const DialectMasterySummary({
    required this.courseId,
    required this.courseName,
    required this.accentHex,
    required this.isInstalled,
    required this.totalWords,
    required this.masteredWords,
    required this.completedLessons,
    required this.totalLessons,
    required this.averageAccuracy,
  });

  final String courseId;
  final String courseName;
  final String accentHex;
  final bool isInstalled;
  final int totalWords;
  final int masteredWords;
  final int completedLessons;
  final int totalLessons;
  final double averageAccuracy;

  double get lessonRatio =>
      totalLessons <= 0 ? 0.0 : (completedLessons / totalLessons).clamp(0.0, 1.0);
  double get wordRatio =>
      totalWords <= 0 ? 0.0 : (masteredWords / totalWords).clamp(0.0, 1.0);
}

