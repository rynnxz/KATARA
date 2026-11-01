import 'package:katara/data/content/content_models.dart';
import 'package:katara/domain/entities/user_progress.dart';

abstract class ContentRepository {
  Future<List<LanguageModel>> getLanguages();
  Future<List<CourseModel>> getCourses({String? languageId});
  Future<CourseModel?> getCourse(String courseId);
  Future<List<UnitModel>> getUnits(String courseId);
  Future<UnitModel?> getUnit(String unitId);
  Future<LessonModel?> getLesson(String lessonId);
  Future<List<WordModel>> getWords(String courseId, {String? category, String? query});
  Future<List<PhraseModel>> getPhrases(String courseId);
  Future<List<SentenceModel>> getSentences(String courseId);
  Future<List<DialogueModel>> getDialogues(String courseId);
  Future<List<JawiLetterModel>> getLetters(String courseId);
  Future<List<ArticleModel>> getArticles(String courseId);
  Future<ArticleModel?> getArticle(String articleId);
  Future<List<CollectionCardModel>> getCollectionCards(String courseId);
  Future<List<QuizBankItemModel>> getQuizBank(
    String courseId, {
    String? lessonId,
    bool includeUnverified = false,
  });
  Future<GameConfig> getGameConfig();
  Future<List<AchievementModel>> getAchievements({Set<String> unlockedIds = const {}});
}
