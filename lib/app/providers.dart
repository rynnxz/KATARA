import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/data/repositories/local_content_repository.dart';
import 'package:katara/data/repositories/local_progress_repository.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/domain/repositories/content_repository.dart';
import 'package:katara/domain/repositories/progress_repository.dart';
import 'package:katara/services/audio_service.dart';
import 'package:katara/services/firebase_sync_service.dart';
import 'package:katara/services/module_download_service.dart';
import 'package:katara/services/notification_service.dart';
import 'package:katara/services/settings_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final contentSeederProvider = Provider<ContentSeeder>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ContentSeeder(db: db);
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalContentRepository(db: db);
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final contentRepo = ref.watch(contentRepositoryProvider);
  return LocalProgressRepository(db: db, contentRepository: contentRepo);
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

class AppSettingsController extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    _loadInitial();
    return const AppSettingsState();
  }

  Future<void> _loadInitial() async {
    final service = ref.read(settingsServiceProvider);
    final loaded = await service.load();
    state = loaded;
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final next = state.copyWith(themeMode: mode);
    state = next;
    await ref.read(settingsServiceProvider).save(next);
  }

  Future<void> toggleSound(bool enabled) async {
    final next = state.copyWith(soundEnabled: enabled);
    state = next;
    await ref.read(settingsServiceProvider).save(next);
  }

  Future<void> toggleHaptic(bool enabled) async {
    final next = state.copyWith(hapticEnabled: enabled);
    state = next;
    await ref.read(settingsServiceProvider).save(next);
  }

  Future<void> updateReminder({bool? enabled, int? hour, int? minute}) async {
    final next = state.copyWith(
      reminderEnabled: enabled ?? state.reminderEnabled,
      reminderHour: hour ?? state.reminderHour,
      reminderMinute: minute ?? state.reminderMinute,
    );
    state = next;
    await ref.read(settingsServiceProvider).save(next);
  }

  Future<void> toggleShowJawi(bool enabled) async {
    final next = state.copyWith(showJawiScript: enabled);
    state = next;
    await ref.read(settingsServiceProvider).save(next);
  }

  void toggleDebugUnverified(bool enabled) {
    state = state.copyWith(debugIncludeUnverified: enabled);
  }

  Future<void> setAuthMode(String? mode) async {
    final next = mode == null
        ? state.copyWith(clearAuthMode: true)
        : state.copyWith(authMode: mode);
    state = next;
    await ref.read(settingsServiceProvider).save(next);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettingsState>(
      AppSettingsController.new,
    );

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = NoopAudioService();
  ref.onDispose(service.dispose);
  return service;
});

final sfxServiceProvider = Provider<SfxService>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return DefaultSfxService(
    soundEnabled: settings.soundEnabled,
    hapticEnabled: settings.hapticEnabled,
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

final userStatsStreamProvider = StreamProvider<UserStats>((ref) {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.watchStats();
});

final languagesProvider = FutureProvider<List<LanguageModel>>((ref) {
  return ref.watch(contentRepositoryProvider).getLanguages();
});

final coursesProvider = FutureProvider<List<CourseModel>>((ref) {
  return ref.watch(contentRepositoryProvider).getCourses();
});

final activeCourseProvider = FutureProvider<CourseModel?>((ref) async {
  final statsAsync = await ref.watch(userStatsStreamProvider.future);
  final courseId = statsAsync.activeCourseId ?? 'ms-deli';
  return ref.watch(contentRepositoryProvider).getCourse(courseId);
});

final courseUnitsProvider = FutureProvider.family<List<UnitModel>, String>((
  ref,
  courseId,
) {
  return ref.watch(contentRepositoryProvider).getUnits(courseId);
});

final courseProgressStreamProvider =
    StreamProvider.family<Map<String, CourseProgress>, String>((ref, courseId) {
      return ref
          .watch(progressRepositoryProvider)
          .watchCourseProgress(courseId);
    });

final gameConfigProvider = FutureProvider<GameConfig>((ref) {
  return ref.watch(contentRepositoryProvider).getGameConfig();
});

class LastLessonResultNotifier extends Notifier<LessonResult?> {
  @override
  LessonResult? build() => null;

  void setResult(LessonResult? result) {
    state = result;
  }
}

final lastLessonResultProvider =
    NotifierProvider<LastLessonResultNotifier, LessonResult?>(
      LastLessonResultNotifier.new,
    );

final moduleDownloadServiceProvider = Provider<ModuleDownloadService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final seeder = ref.watch(contentSeederProvider);
  return ModuleDownloadService(db: db, seeder: seeder);
});

final moduleCatalogProvider = FutureProvider<List<ModuleCatalogItemModel>>((
  ref,
) {
  return ref.watch(moduleDownloadServiceProvider).loadCatalog();
});

final installedModulesProvider = FutureProvider<List<InstalledModuleModel>>((
  ref,
) {
  return ref.watch(contentRepositoryProvider).getInstalledModules();
});

final dialectReferencesProvider =
    FutureProvider.family<List<DialectReferenceModel>, String?>((
      ref,
      courseId,
    ) {
      return ref
          .watch(contentRepositoryProvider)
          .getDialectReferences(courseId);
    });

final dialectComparisonProvider =
    FutureProvider.family<List<DialectComparisonRowModel>, String?>((
      ref,
      category,
    ) async {
      final rows = await ref
          .watch(contentRepositoryProvider)
          .getDialectComparisonRows();
      if (category == null || category == 'semua' || category.isEmpty) {
        return rows;
      }
      return rows.where((r) => r.category == category).toList();
    });

final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FirebaseSyncService(db: db);
});

final cloudProfileProvider = FutureProvider<CloudProfile>((ref) {
  return ref.watch(firebaseSyncServiceProvider).getCurrentProfile();
});
