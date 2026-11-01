import 'package:katara/domain/entities/user_progress.dart';

abstract class ProgressRepository {
  Stream<UserStats> watchStats();
  Future<UserStats> getStats();
  Future<void> updateProfile({
    String? displayName,
    String? learningGoal,
    int? dailyGoalMinutes,
    String? activeCourseId,
    bool? casualMode,
    bool? onboardingCompleted,
  });
  Future<Map<String, CourseProgress>> getCourseProgress(String courseId);
  Stream<Map<String, CourseProgress>> watchCourseProgress(String courseId);
  Future<LessonResult> completeLesson(LessonAttempt attempt);
  Future<List<WordMastery>> dueForReview(String courseId, {int limit = 20});
  Future<List<WordMastery>> getCourseMastery(String courseId);
  Future<void> recordPracticeReview({
    required String courseId,
    required List<ItemAttemptOutcome> outcomes,
    required int xpEarned,
  });
  Future<List<DailyQuestProgress>> getDailyQuests();
  Future<int> claimQuestReward(String questId);
  Future<int?> claimDailyChest();
  Future<bool> isDailyChestClaimedToday();
  Future<Set<String>> getUnlockedAchievements();
  Future<Set<String>> getUnlockedCards(String courseId);
  Future<void> unlockArticleAndCard({
    required String courseId,
    required String articleId,
    String? cardId,
  });
  Future<Map<String, int>> getInventory();
  Future<bool> buyShopItem(ShopItemConfig item);
  Future<bool> spendHeart();
  Future<Map<String, int>> getWeeklyXpByDate({int days = 7});
  Future<Set<String>> getActiveDatesHistory();
  Future<void> submitReport({
    required String courseId,
    required String itemId,
    required String itemType,
    required String reason,
    String? note,
  });
  Future<void> resetAllUserData();
}
