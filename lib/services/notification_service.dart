import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:katara/core/app_logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Layanan notifikasi pengingat streak lokal tanpa server/FCM (Bagian 9).
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissionWithContext();
  Future<void> rescheduleStreakReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
    required int currentStreak,
  });
  Future<void> rescheduleDailyReminder({
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
    int currentStreak = 1,
  }) =>
      rescheduleStreakReminder(
        enabled: true,
        hour: hour,
        minute: minute,
        alreadyStudiedToday: alreadyStudiedToday,
        currentStreak: currentStreak,
      );
  Future<void> cancelAll() => rescheduleStreakReminder(
        enabled: false,
        hour: 19,
        minute: 30,
        alreadyStudiedToday: false,
        currentStreak: 0,
      );
  DateTime computeNextReminderTime({
    required DateTime now,
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
  });
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _streakNotificationId = 1001;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (e) {
      AppLogger.warning('Inisialisasi notifikasi lokal dilewati', error: e);
    }
  }

  @override
  Future<bool> requestPermissionWithContext() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  DateTime computeNextReminderTime({
    required DateTime now,
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
  }) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (alreadyStudiedToday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  @override
  Future<void> rescheduleStreakReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
    required int currentStreak,
  }) async {
    try {
      await initialize();
      await _plugin.cancel(id: _streakNotificationId);
      if (!enabled) return;

      final nextDate = computeNextReminderTime(
        now: DateTime.now(),
        hour: hour,
        minute: minute,
        alreadyStudiedToday: alreadyStudiedToday,
      );

      final scheduledTz = tz.TZDateTime.from(nextDate, tz.local);
      final bodyText = currentStreak > 0
          ? 'Api streak $currentStreak hari menunggumu! Luangkan 3 menit belajar Melayu Deli hari ini.'
          : 'Yuk mulai latihan singkat 3 menit bahasa Melayu Deli bersama Si Rebung!';

      const androidDetails = AndroidNotificationDetails(
        'katara_streak_channel',
        'Pengingat Streak Belajar',
        channelDescription: 'Pengingat harian untuk menjaga streak belajar bahasa Melayu',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      await _plugin.zonedSchedule(
        id: _streakNotificationId,
        title: 'Waktunya Belajar di KATARA',
        body: bodyText,
        scheduledDate: scheduledTz,
        notificationDetails:
            const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      AppLogger.warning('Penjadwalan ulang notifikasi gagal', error: e);
    }
  }

  @override
  Future<void> rescheduleDailyReminder({
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
    int currentStreak = 1,
  }) =>
      rescheduleStreakReminder(
        enabled: true,
        hour: hour,
        minute: minute,
        alreadyStudiedToday: alreadyStudiedToday,
        currentStreak: currentStreak,
      );

  @override
  Future<void> cancelAll() => rescheduleStreakReminder(
        enabled: false,
        hour: 19,
        minute: 30,
        alreadyStudiedToday: false,
        currentStreak: 0,
      );
}

class NoopNotificationService implements NotificationService {
  DateTime? lastScheduledTime;
  bool wasCancelled = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissionWithContext() async => true;

  @override
  DateTime computeNextReminderTime({
    required DateTime now,
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
  }) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (alreadyStudiedToday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  @override
  Future<void> rescheduleStreakReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
    required int currentStreak,
  }) async {
    wasCancelled = true;
    if (!enabled) {
      lastScheduledTime = null;
      return;
    }
    lastScheduledTime = computeNextReminderTime(
      now: DateTime.now(),
      hour: hour,
      minute: minute,
      alreadyStudiedToday: alreadyStudiedToday,
    );
  }

  @override
  Future<void> rescheduleDailyReminder({
    required int hour,
    required int minute,
    required bool alreadyStudiedToday,
    int currentStreak = 1,
  }) =>
      rescheduleStreakReminder(
        enabled: true,
        hour: hour,
        minute: minute,
        alreadyStudiedToday: alreadyStudiedToday,
        currentStreak: currentStreak,
      );

  @override
  Future<void> cancelAll() => rescheduleStreakReminder(
        enabled: false,
        hour: 19,
        minute: 30,
        alreadyStudiedToday: false,
        currentStreak: 0,
      );
}
