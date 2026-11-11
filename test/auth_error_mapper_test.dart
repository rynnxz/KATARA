import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/features/profile/profile_screen.dart';
import 'package:katara/services/auth_error_mapper.dart';
import 'package:katara/services/firebase_sync_service.dart';

class _ThrowingCloudSyncGateway extends InMemoryCloudSyncGateway {
  _ThrowingCloudSyncGateway(this.errorToThrow);

  Object? errorToThrow;

  @override
  Future<CloudProfile> signInWithGoogle() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return super.signInWithGoogle();
  }
}

void main() {
  group('AuthErrorMapper unit tests', () {
    test('Maps PlatformException(sign_in_failed, t4: 10:) to friendly Indonesian message without raw leak', () {
      final ex = PlatformException(
        code: 'sign_in_failed',
        message: 'com.google.android.gms.common.api.ApiException: 10: ',
        details: 't4: 10: ',
      );
      final result = AuthErrorMapper.map(ex);

      expect(result.category, AuthErrorCategory.configuration);
      expect(result.isBenignCancel, isFalse);
      expect(result.userMessage, contains('Mode Tamu'));
      expect(result.userMessage.toLowerCase(), isNot(contains('platformexception')));
      expect(result.userMessage.toLowerCase(), isNot(contains('t4: 10')));
      expect(result.userMessage.toLowerCase(), isNot(contains('apiexception')));
    });

    test('Maps user cancellation (sign_in_canceled / 12501 / StateError) as benign cancel', () {
      final platformCancel = PlatformException(
        code: 'sign_in_canceled',
        message: '12501: ',
      );
      final res1 = AuthErrorMapper.map(platformCancel);
      expect(res1.category, AuthErrorCategory.canceled);
      expect(res1.isBenignCancel, isTrue);
      expect(res1.userMessage, contains('dibatalkan'));

      final stateCancel = StateError('Login Google dibatalkan oleh pengguna.');
      final res2 = AuthErrorMapper.map(stateCancel);
      expect(res2.category, AuthErrorCategory.canceled);
      expect(res2.isBenignCancel, isTrue);
    });

    test('Maps network errors (network_error / 7 / network-request-failed)', () {
      final netPlatform = PlatformException(
        code: 'network_error',
        message: '7: Network error',
      );
      expect(AuthErrorMapper.map(netPlatform).category, AuthErrorCategory.network);

      final netFirebase = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'A network error has occurred.',
      );
      expect(AuthErrorMapper.map(netFirebase).category, AuthErrorCategory.network);
      expect(AuthErrorMapper.toUserMessage(netFirebase), contains('Koneksi internet'));
    });

    test('Maps FirebaseAuthException credential conflict, disabled user, and requires-recent-login', () {
      final conflict = FirebaseAuthException(code: 'credential-already-in-use');
      expect(AuthErrorMapper.map(conflict).category, AuthErrorCategory.credentialConflict);

      final disabled = FirebaseAuthException(code: 'user-disabled');
      expect(AuthErrorMapper.map(disabled).category, AuthErrorCategory.userDisabled);

      final recentLogin = FirebaseAuthException(code: 'requires-recent-login');
      expect(AuthErrorMapper.map(recentLogin).category, AuthErrorCategory.requiresRecentLogin);
      expect(AuthErrorMapper.toUserMessage(recentLogin), contains('masuk kembali'));
    });
  });

  group('FirebaseSyncService Guest resilience, merge, & account deletion', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.ensureInitialized();
    });

    tearDown(() async {
      await db.close();
    });

    test('Failed Google Sign-In keeps Guest profile and local progress 100% intact, then merges on success', () async {
      final gateway = _ThrowingCloudSyncGateway(
        PlatformException(code: 'sign_in_failed', message: 't4: 10: '),
      );
      final service = FirebaseSyncService(db: db, gateway: gateway);

      final initialProfile = await service.getCurrentProfile();
      expect(initialProfile.isGuest, isTrue);

      // Insert local guest lesson progress
      await db.customStatement(
        '''
        INSERT INTO course_progress (course_id, lesson_id, stars, best_score, completed_at, is_synced, updated_at)
        VALUES ('ms-deli', 'ms-deli-u1-l1', 3, 95, '2026-11-11T07:00:00Z', 0, '2026-11-11T07:00:00Z')
        ''',
      );

      // Attempt sign-in -> throws PlatformException(sign_in_failed)
      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<PlatformException>()),
      );

      // Verify Guest profile & local progress are untouched
      final afterFailProfile = await service.getCurrentProfile();
      expect(afterFailProfile.isGuest, isTrue);
      expect(afterFailProfile.uid, initialProfile.uid);

      final localRows = await db.customSelect('SELECT * FROM course_progress').get();
      expect(localRows.length, 1);
      expect(localRows.first.read<int>('stars'), 3);

      // Now fix gateway and sign in -> local guest progress is queued and synced
      gateway.errorToThrow = null;
      final googleProfile = await service.signInWithGoogle();
      expect(googleProfile.isGuest, isFalse);
      expect(googleProfile.uid, 'google-uid-katara-001');

      final report = await service.syncNow();
      expect(report.pushedItems, greaterThanOrEqualTo(1));

      final remoteDocs = await gateway.pullCollection(
        uid: 'google-uid-katara-001',
        collectionName: 'dialect_progress',
      );
      expect(remoteDocs.length, 1);
      expect(remoteDocs.first['lesson_id'], 'ms-deli-u1-l1');
      expect(remoteDocs.first['stars'], 3);

      // Delete account & cloud data -> cloud cleared, reverts to Guest, local progress kept
      final revertedGuest = await service.deleteAccountAndCloudData();
      expect(revertedGuest.isGuest, isTrue);
      final remoteAfterDelete = await gateway.pullCollection(
        uid: 'google-uid-katara-001',
        collectionName: 'dialect_progress',
      );
      expect(remoteAfterDelete, isEmpty);
    });
  });

  group('ProfileScreen Google Sign-In error snackbar widget test', () {
    testWidgets('Shows friendly Indonesian snackbar on PlatformException(sign_in_failed) without leaking raw exception', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.ensureInitialized();
      addTearDown(() => db.close());

      final gateway = _ThrowingCloudSyncGateway(
        PlatformException(
          code: 'sign_in_failed',
          message: 't4: 10: ',
        ),
      );
      final syncService = FirebaseSyncService(db: db, gateway: gateway);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            firebaseSyncServiceProvider.overrideWithValue(syncService),
          ],
          child: MaterialApp(
            theme: KataraTheme.light(),
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final signInBtn = find.text('Masuk dengan Google');
      expect(signInBtn, findsOneWidget);

      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Friendly message is shown
      expect(
        find.textContaining('Progres belajarmu tetap tersimpan aman di perangkat (Mode Tamu)'),
        findsOneWidget,
      );
      // Raw technical string is NEVER shown
      expect(find.textContaining('PlatformException'), findsNothing);
      expect(find.textContaining('t4: 10'), findsNothing);
    });
  });
}
