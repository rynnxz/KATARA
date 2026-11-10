import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/firebase_options.dart';

class XpEventRecord {
  const XpEventRecord({
    required this.eventId,
    required this.courseId,
    required this.sourceType,
    required this.sourceRef,
    required this.deltaXp,
    required this.createdAt,
    required this.deviceId,
  });

  final String eventId;
  final String courseId;
  final String sourceType;
  final String sourceRef;
  final int deltaXp;
  final DateTime createdAt;
  final String deviceId;

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'course_id': courseId,
        'source_type': sourceType,
        'source': '$sourceType:$sourceRef',
        'delta_xp': deltaXp,
        'amount': deltaXp,
        'created_at': createdAt.toIso8601String(),
        'device_id': deviceId,
      };
}

class CloudProfile {
  const CloudProfile({
    required this.uid,
    required this.displayName,
    required this.authProvider,
    this.email,
    this.photoUrl,
    this.lastSyncedAt,
  });

  final String uid;
  final String displayName;
  final String authProvider; // 'guest' | 'google'
  final String? email;
  final String? photoUrl;
  final DateTime? lastSyncedAt;

  bool get isGuest => authProvider == 'guest';
}

class SyncReport {
  const SyncReport({
    required this.pushedItems,
    required this.pulledItems,
    required this.failedItems,
    required this.syncedAt,
  });

  final int pushedItems;
  final int pulledItems;
  final int failedItems;
  final DateTime syncedAt;
}

class ConflictResolver {
  const ConflictResolver._();

  /// Menggabungkan progres pelajaran dari lokal dan cloud tanpa menurunkan bintang/skor.
  static CourseProgress mergeCourseProgress(
    CourseProgress local,
    CourseProgress remote,
  ) {
    final latestCompleted = local.completedAt.isAfter(remote.completedAt)
        ? local.completedAt
        : remote.completedAt;
    return CourseProgress(
      courseId: local.courseId,
      lessonId: local.lessonId,
      stars: math.max(local.stars, remote.stars),
      bestScore: math.max(local.bestScore, remote.bestScore),
      completedAt: latestCompleted,
    );
  }

  /// Menggabungkan penguasaan kosakata SRS dari lokal dan cloud.
  static WordMastery mergeWordMastery(
    WordMastery local,
    WordMastery remote,
  ) {
    final latestSeen = local.lastSeenAt.isAfter(remote.lastSeenAt)
        ? local.lastSeenAt
        : remote.lastSeenAt;
    final latestReview = local.nextReviewAt.isAfter(remote.nextReviewAt)
        ? local.nextReviewAt
        : remote.nextReviewAt;
    return WordMastery(
      courseId: local.courseId,
      itemId: local.itemId,
      itemType: local.itemType,
      strength: math.max(local.strength, remote.strength),
      correctCount: math.max(local.correctCount, remote.correctCount),
      wrongCount: math.max(local.wrongCount, remote.wrongCount),
      lastSeenAt: latestSeen,
      nextReviewAt: latestReview,
    );
  }

  /// Menggabungkan log XP secara idempoten berdasarkan `eventId` unik.
  static List<XpEventRecord> mergeXpEvents(
    List<XpEventRecord> local,
    List<XpEventRecord> remote,
  ) {
    final byId = <String, XpEventRecord>{};
    for (final e in remote) {
      byId[e.eventId] = e;
    }
    for (final e in local) {
      byId[e.eventId] = e;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  static int calculateMergedXp({
    required int localXp,
    required int remoteXp,
    required List<XpEventRecord> mergedEvents,
  }) {
    final eventsSum = mergedEvents.fold<int>(0, (acc, e) => acc + e.deltaXp);
    return math.max(math.max(localXp, remoteXp), eventsSum);
  }
}

abstract class CloudSyncGateway {
  Future<CloudProfile?> getAuthenticatedUser();
  Future<CloudProfile> signInWithGoogle();
  Future<void> signOut();
  Future<void> pushEntity({
    required String uid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  });
  Future<List<Map<String, dynamic>>> pullCollection({
    required String uid,
    required String collectionName,
  });
}

class InMemoryCloudSyncGateway implements CloudSyncGateway {
  CloudProfile? _user;
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};

  @override
  Future<CloudProfile?> getAuthenticatedUser() async => _user;

  @override
  Future<CloudProfile> signInWithGoogle() async {
    _user = const CloudProfile(
      uid: 'google-uid-katara-001',
      displayName: 'Pelajar Melayu',
      email: 'pelajar@katara.id',
      authProvider: 'google',
    );
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<void> pushEntity({
    required String uid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final colKey = '$uid/$entityType';
    _store.putIfAbsent(colKey, () => {})[entityId] = Map<String, dynamic>.from(payload);
  }

  @override
  Future<List<Map<String, dynamic>>> pullCollection({
    required String uid,
    required String collectionName,
  }) async {
    final colKey = '$uid/$collectionName';
    return _store[colKey]?.values.toList() ?? const [];
  }
}

class FirestoreCloudSyncGateway implements CloudSyncGateway {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _initialized = true;
  }

  @override
  Future<CloudProfile?> getAuthenticatedUser() async {
    try {
      await _ensureInitialized();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return CloudProfile(
        uid: user.uid,
        displayName: user.displayName ?? 'Pelajar Melayu',
        email: user.email,
        photoUrl: user.photoURL,
        authProvider: user.isAnonymous ? 'guest' : 'google',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CloudProfile> signInWithGoogle() async {
    await _ensureInitialized();
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw StateError('Login Google dibatalkan oleh pengguna.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user!;
    return CloudProfile(
      uid: user.uid,
      displayName: user.displayName ?? googleUser.displayName ?? 'Pelajar Melayu',
      email: user.email ?? googleUser.email,
      photoUrl: user.photoURL ?? googleUser.photoUrl,
      authProvider: 'google',
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  Future<void> pushEntity({
    required String uid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    await _ensureInitialized();
    final firestore = FirebaseFirestore.instance;
    if (entityType == 'user_profile') {
      await firestore.collection('users').doc(uid).set(payload, SetOptions(merge: true));
      return;
    }
    await firestore
        .collection('users')
        .doc(uid)
        .collection(entityType)
        .doc(entityId)
        .set(payload, SetOptions(merge: true));
  }

  @override
  Future<List<Map<String, dynamic>>> pullCollection({
    required String uid,
    required String collectionName,
  }) async {
    await _ensureInitialized();
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collectionName)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}

class FirebaseSyncService {
  FirebaseSyncService({
    required this.db,
    CloudSyncGateway? gateway,
    DateTime Function()? clock,
  })  : _gateway = gateway ?? FirestoreCloudSyncGateway(),
        _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final CloudSyncGateway _gateway;
  final DateTime Function() _clock;
  static final _rng = math.Random();

  static String _shortRandomHex() =>
      _rng.nextInt(0x7FFFFFFF).toRadixString(16).padLeft(8, '0');

  Future<CloudProfile> getCurrentProfile() async {
    await db.ensureInitialized();
    final rows = await db.customSelect('SELECT * FROM user_profiles LIMIT 1').get();
    if (rows.isNotEmpty) {
      final r = rows.first;
      final isAnon = r.read<int>('is_anonymous') == 1;
      final lastSyncRaw = r.readNullable<String>('last_synced_at');
      return CloudProfile(
        uid: r.read<String>('uid'),
        displayName: r.readNullable<String>('display_name') ?? 'Pelajar',
        email: r.readNullable<String>('email'),
        photoUrl: r.readNullable<String>('photo_url'),
        authProvider: isAnon ? 'guest' : 'google',
        lastSyncedAt: lastSyncRaw != null ? DateTime.tryParse(lastSyncRaw) : null,
      );
    }

    final nowIso = _clock().toIso8601String();
    final guestUid = 'guest-${_shortRandomHex()}';
    await db.customStatement(
      '''
      INSERT INTO user_profiles (
        uid, email, display_name, photo_url, is_anonymous,
        device_id, revision, last_synced_at, created_at, updated_at
      ) VALUES (?, NULL, 'Pelajar (Tamu)', NULL, 1, 'local-device', 1, NULL, ?, ?)
      ''',
      [guestUid, nowIso, nowIso],
    );
    return CloudProfile(
      uid: guestUid,
      displayName: 'Pelajar (Tamu)',
      authProvider: 'guest',
    );
  }

  Future<CloudProfile> signInWithGoogle() async {
    await db.ensureInitialized();
    final profile = await _gateway.signInWithGoogle();
    final nowIso = _clock().toIso8601String();

    await db.customStatement('DELETE FROM user_profiles');
    await db.customStatement(
      '''
      INSERT INTO user_profiles (
        uid, email, display_name, photo_url, is_anonymous,
        device_id, revision, last_synced_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, 0, 'local-device', 1, NULL, ?, ?)
      ''',
      [
        profile.uid,
        profile.email,
        profile.displayName,
        profile.photoUrl,
        nowIso,
        nowIso,
      ],
    );
    await db.customStatement(
      'UPDATE user_stats SET display_name = ?, updated_at = ? WHERE id = 1',
      [profile.displayName, nowIso],
    );
    db.notifyTableChanged('user_stats');
    return profile;
  }

  Future<CloudProfile> signOutToGuest() async {
    await db.ensureInitialized();
    await _gateway.signOut();
    await db.customStatement('DELETE FROM user_profiles');
    return getCurrentProfile();
  }

  Future<int> getPendingQueueCount() async {
    await db.ensureInitialized();
    final row = await db
        .customSelect('SELECT COUNT(*) AS cnt FROM sync_queue')
        .getSingle();
    return row.read<int>('cnt');
  }

  Future<SyncReport> syncNow() async {
    await db.ensureInitialized();
    final profile = await getCurrentProfile();
    final now = _clock();
    final nowIso = now.toIso8601String();

    var pushed = 0;
    var pulled = 0;
    var failed = 0;

    final queueRows = await db.customSelect(
      '''
      SELECT * FROM sync_queue
      WHERE next_retry_at IS NULL OR next_retry_at <= ?
      ORDER BY id ASC
      LIMIT 100
      ''',
      variables: [Variable.withString(nowIso)],
    ).get();

    for (final row in queueRows) {
      final id = row.read<int>('id');
      final entityType = row.read<String>('entity_type');
      final entityId = row.read<String>('entity_id');
      final payloadJson = row.read<String>('payload_json');
      final retryCount = row.read<int>('retry_count');

      try {
        final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
        await _gateway.pushEntity(
          uid: profile.uid,
          entityType: entityType,
          entityId: entityId,
          payload: payload,
        );
        await db.customStatement('DELETE FROM sync_queue WHERE id = ?', [id]);
        pushed++;
      } catch (e) {
        failed++;
        final nextRetryCount = retryCount + 1;
        final backoffSeconds = math.min(3600, math.pow(2, nextRetryCount).toInt() * 5);
        final nextRetryAt = now.add(Duration(seconds: backoffSeconds)).toIso8601String();
        await db.customStatement(
          '''
          UPDATE sync_queue
          SET retry_count = ?, next_retry_at = ?, last_error = ?
          WHERE id = ?
          ''',
          [nextRetryCount, nextRetryAt, e.toString(), id],
        );
      }
    }

    // Pull & merge remote progress if authenticated
    if (!profile.isGuest) {
      try {
        final remoteProgress = await _gateway.pullCollection(
          uid: profile.uid,
          collectionName: 'dialect_progress',
        );
        for (final doc in remoteProgress) {
          final courseId = doc['course_id'] as String? ?? '';
          final lessonId = doc['lesson_id'] as String? ?? '';
          if (courseId.isEmpty || lessonId.isEmpty) continue;
          final remoteItem = CourseProgress(
            courseId: courseId,
            lessonId: lessonId,
            stars: (doc['stars'] as num?)?.toInt() ?? 0,
            bestScore: (doc['best_score'] as num?)?.toInt() ?? 0,
            completedAt: DateTime.tryParse(doc['completed_at'] as String? ?? '') ?? now,
          );

          final localRows = await db.customSelect(
            'SELECT * FROM course_progress WHERE course_id = ? AND lesson_id = ? LIMIT 1',
            variables: [Variable.withString(courseId), Variable.withString(lessonId)],
          ).get();

          final merged = localRows.isEmpty
              ? remoteItem
              : ConflictResolver.mergeCourseProgress(
                  CourseProgress(
                    courseId: courseId,
                    lessonId: lessonId,
                    stars: localRows.first.read<int>('stars'),
                    bestScore: localRows.first.read<int>('best_score'),
                    completedAt: DateTime.tryParse(
                          localRows.first.read<String>('completed_at'),
                        ) ??
                        now,
                  ),
                  remoteItem,
                );

          await db.customStatement(
            '''
            INSERT INTO course_progress (course_id, lesson_id, stars, best_score, completed_at, is_synced, updated_at)
            VALUES (?, ?, ?, ?, ?, 1, ?)
            ON CONFLICT(course_id, lesson_id) DO UPDATE SET
              stars = excluded.stars,
              best_score = excluded.best_score,
              completed_at = excluded.completed_at,
              is_synced = 1,
              updated_at = excluded.updated_at
            ''',
            [
              merged.courseId,
              merged.lessonId,
              merged.stars,
              merged.bestScore,
              merged.completedAt.toIso8601String(),
              nowIso,
            ],
          );
          pulled++;
        }
      } catch (_) {}
    }

    await db.customStatement(
      'UPDATE user_profiles SET last_synced_at = ?, updated_at = ? WHERE uid = ?',
      [nowIso, nowIso, profile.uid],
    );
    await db.customStatement('UPDATE xp_events SET is_synced = 1 WHERE is_synced = 0');

    return SyncReport(
      pushedItems: pushed,
      pulledItems: pulled,
      failedItems: failed,
      syncedAt: now,
    );
  }
}
