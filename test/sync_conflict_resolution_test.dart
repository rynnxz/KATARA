import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/data/repositories/local_content_repository.dart';
import 'package:katara/data/repositories/local_progress_repository.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/services/firebase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloud Sync Conflict Resolution & Offline Queue Tests', () {
    late AppDatabase db;
    late LocalContentRepository contentRepo;
    late LocalProgressRepository progressRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.ensureInitialized();
      final seeder = ContentSeeder(db: db);
      await seeder.seedIfNeeded();
      contentRepo = LocalContentRepository(db: db);
      progressRepo = LocalProgressRepository(
        db: db,
        contentRepository: contentRepo,
        clock: () => DateTime.utc(2026, 11, 11, 10, 0, 0),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('ConflictResolver merges course progress, word mastery, XP events, and streak history deterministically', () {
      final localProg = CourseProgress(
        courseId: 'ms-deli',
        lessonId: 'ms-deli:l:0001',
        stars: 2,
        bestScore: 85,
        completedAt: DateTime.utc(2026, 11, 10, 12, 0),
      );
      final remoteProg = CourseProgress(
        courseId: 'ms-deli',
        lessonId: 'ms-deli:l:0001',
        stars: 3,
        bestScore: 95,
        completedAt: DateTime.utc(2026, 11, 09, 12, 0),
      );

      final mergedProg = ConflictResolver.mergeCourseProgress(
        localProg,
        remoteProg,
      );
      expect(mergedProg.stars, equals(3));
      expect(mergedProg.bestScore, equals(95));
      expect(mergedProg.completedAt, equals(DateTime.utc(2026, 11, 10, 12, 0)));

      final localMastery = WordMastery(
        courseId: 'ms-langkat',
        itemId: 'ms-langkat:w:0001',
        itemType: 'word',
        strength: 4,
        correctCount: 5,
        wrongCount: 1,
        lastSeenAt: DateTime.utc(2026, 11, 11, 8, 0),
        nextReviewAt: DateTime.utc(2026, 11, 18, 8, 0),
      );
      final remoteMastery = WordMastery(
        courseId: 'ms-langkat',
        itemId: 'ms-langkat:w:0001',
        itemType: 'word',
        strength: 2,
        correctCount: 3,
        wrongCount: 2,
        lastSeenAt: DateTime.utc(2026, 11, 10, 8, 0),
        nextReviewAt: DateTime.utc(2026, 11, 12, 8, 0),
      );

      final mergedMastery = ConflictResolver.mergeWordMastery(
        localMastery,
        remoteMastery,
      );
      expect(mergedMastery.strength, equals(4));
      expect(mergedMastery.correctCount, equals(5));
      expect(mergedMastery.wrongCount, equals(2));
      expect(
        mergedMastery.nextReviewAt,
        equals(DateTime.utc(2026, 11, 18, 8, 0)),
      );

      final localEvents = [
        XpEventRecord(
          eventId: 'evt-1',
          courseId: 'ms-deli',
          sourceType: 'lesson',
          sourceRef: 'ms-deli:l:0001',
          deltaXp: 25,
          createdAt: DateTime.utc(2026, 11, 10),
          deviceId: 'dev-a',
        ),
        XpEventRecord(
          eventId: 'evt-2',
          courseId: 'ms-langkat',
          sourceType: 'lesson',
          sourceRef: 'ms-langkat:l:0001',
          deltaXp: 30,
          createdAt: DateTime.utc(2026, 11, 11),
          deviceId: 'dev-a',
        ),
      ];
      final remoteEvents = [
        XpEventRecord(
          eventId: 'evt-1',
          courseId: 'ms-deli',
          sourceType: 'lesson',
          sourceRef: 'ms-deli:l:0001',
          deltaXp: 25,
          createdAt: DateTime.utc(2026, 11, 10),
          deviceId: 'dev-a',
        ),
        XpEventRecord(
          eventId: 'evt-3',
          courseId: 'ms-palembang',
          sourceType: 'practice',
          sourceRef: 'srs',
          deltaXp: 15,
          createdAt: DateTime.utc(2026, 11, 11),
          deviceId: 'dev-b',
        ),
      ];

      final unionEvents = ConflictResolver.mergeXpEvents(
        localEvents,
        remoteEvents,
      );
      expect(unionEvents.length, equals(3));
      final totalXp = ConflictResolver.calculateMergedXp(
        localXp: 55,
        remoteXp: 40,
        mergedEvents: unionEvents,
      );
      expect(totalXp, equals(70)); // 25 + 30 + 15 = 70
    });

    test('Completing a lesson records xp_events, streak_history, and sync_queue entries automatically', () async {
      final result = await progressRepo.completeLesson(
        const LessonAttempt(
          courseId: 'ms-deli',
          unitId: 'ms-deli:u:0001',
          lessonId: 'ms-deli:l:0001',
          lessonKind: 'regular',
          totalQuestions: 10,
          correctFirstTryCount: 10,
          wrongCount: 0,
          maxCombo: 6,
          itemOutcomes: [
            ItemAttemptOutcome(
              itemId: 'ms-deli:w:0001',
              itemType: 'word',
              isCorrect: true,
            ),
          ],
        ),
      );

      expect(result.xpEarned, greaterThan(0));

      final xpEventRows = await db
          .customSelect('SELECT * FROM xp_events')
          .get();
      expect(xpEventRows, isNotEmpty);

      final streakRows = await db
          .customSelect('SELECT * FROM streak_history')
          .get();
      expect(streakRows, isNotEmpty);

      final queueRows = await db.customSelect('SELECT * FROM sync_queue').get();
      expect(queueRows, isNotEmpty);
    });

    test('FirebaseSyncService flushes offline sync_queue via CloudSyncGateway and supports Guest-to-Google upgrade', () async {
      final gateway = InMemoryCloudSyncGateway();
      final syncService = FirebaseSyncService(db: db, gateway: gateway);

      // Start in guest mode
      final initialUser = await syncService.getCurrentProfile();
      expect(initialUser.authProvider, equals('guest'));

      // Complete a lesson while offline/guest
      await progressRepo.completeLesson(
        const LessonAttempt(
          courseId: 'ms-deli',
          unitId: 'ms-deli:u:0001',
          lessonId: 'ms-deli:l:0001',
          lessonKind: 'regular',
          totalQuestions: 10,
          correctFirstTryCount: 9,
          wrongCount: 1,
          maxCombo: 4,
          itemOutcomes: [],
        ),
      );

      final pendingBefore = await syncService.getPendingQueueCount();
      expect(pendingBefore, greaterThan(0));

      // Sign in with Google (simulated via gateway)
      final signedInProfile = await syncService.signInWithGoogle();
      expect(signedInProfile.authProvider, equals('google'));
      expect(signedInProfile.email, isNotEmpty);

      // Flush sync queue & reconcile with remote
      final report = await syncService.syncNow();
      expect(report.pushedItems, greaterThan(0));

      final pendingAfter = await syncService.getPendingQueueCount();
      expect(pendingAfter, equals(0));
    });
  });
}
