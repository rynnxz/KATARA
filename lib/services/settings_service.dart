import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  const AppSettingsState({
    this.themeMode = ThemeMode.light,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.reminderEnabled = true,
    this.reminderHour = 19,
    this.reminderMinute = 30,
    this.showJawiScript = true,
    this.debugIncludeUnverified = false,
    this.authMode,
  });

  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool showJawiScript;
  final bool debugIncludeUnverified;
  final String? authMode; // 'google' | 'guest' | null

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? showJawiScript,
    bool? debugIncludeUnverified,
    String? authMode,
    bool clearAuthMode = false,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      showJawiScript: showJawiScript ?? this.showJawiScript,
      debugIncludeUnverified:
          debugIncludeUnverified ?? this.debugIncludeUnverified,
      authMode: clearAuthMode ? null : (authMode ?? this.authMode),
    );
  }
}

class SettingsService {
  static const _kThemeMode = 'katara.theme_mode';
  static const _kSound = 'katara.sound_enabled';
  static const _kHaptic = 'katara.haptic_enabled';
  static const _kReminderEnabled = 'katara.reminder_enabled';
  static const _kReminderHour = 'katara.reminder_hour';
  static const _kReminderMinute = 'katara.reminder_minute';
  static const _kShowJawi = 'katara.show_jawi';
  static const _kAuthMode = 'katara.auth_mode';

  Future<AppSettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_kThemeMode) ?? 'light';
    final themeMode = switch (themeStr) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };

    return AppSettingsState(
      themeMode: themeMode,
      soundEnabled: prefs.getBool(_kSound) ?? true,
      hapticEnabled: prefs.getBool(_kHaptic) ?? true,
      reminderEnabled: prefs.getBool(_kReminderEnabled) ?? true,
      reminderHour: prefs.getInt(_kReminderHour) ?? 19,
      reminderMinute: prefs.getInt(_kReminderMinute) ?? 30,
      showJawiScript: prefs.getBool(_kShowJawi) ?? true,
      authMode: prefs.getString(_kAuthMode),
    );
  }

  Future<void> save(AppSettingsState state) async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = switch (state.themeMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await prefs.setString(_kThemeMode, themeStr);
    await prefs.setBool(_kSound, state.soundEnabled);
    await prefs.setBool(_kHaptic, state.hapticEnabled);
    await prefs.setBool(_kReminderEnabled, state.reminderEnabled);
    await prefs.setInt(_kReminderHour, state.reminderHour);
    await prefs.setInt(_kReminderMinute, state.reminderMinute);
    await prefs.setBool(_kShowJawi, state.showJawiScript);
    if (state.authMode != null && state.authMode!.isNotEmpty) {
      await prefs.setString(_kAuthMode, state.authMode!);
    } else {
      await prefs.remove(_kAuthMode);
    }
  }
}
