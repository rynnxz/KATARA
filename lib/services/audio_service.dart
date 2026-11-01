import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:katara/core/app_logger.dart';

/// Antarmuka layanan audio kata/frasa (Bagian 2.4 & Bagian 9).
/// Saat `audio_path` kosong, UI menyembunyikan tombol speaker dan latihan dengar.
abstract class AudioService {
  Future<void> playAsset(String? assetPath);
  Future<void> preloadAssets(Iterable<String?> assetPaths);
  Future<void> dispose();
}

class NoopAudioService implements AudioService {
  const NoopAudioService();

  @override
  Future<void> playAsset(String? assetPath) async {}

  @override
  Future<void> preloadAssets(Iterable<String?> assetPaths) async {}

  @override
  Future<void> dispose() async {}
}

class JustAudioService implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playAsset(String? assetPath) async {
    if (assetPath == null || assetPath.trim().isEmpty) return;
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      AppLogger.warning('Audio belum tersedia untuk $assetPath', error: e);
    }
  }

  @override
  Future<void> preloadAssets(Iterable<String?> assetPaths) async {
    for (final path in assetPaths) {
      if (path == null || path.trim().isEmpty) continue;
      try {
        await _player.setAsset(path);
        break;
      } catch (_) {
        // Abaikan bila file aset audio belum ada.
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Antarmuka efek suara & umpan balik haptic (Bagian 10.5).
abstract class SfxService {
  Future<void> onCorrect({bool haptic = true});
  Future<void> onWrong({bool haptic = true});
  Future<void> onLevelUp({bool haptic = true});
  Future<void> playCorrect() => onCorrect();
  Future<void> playWrong() => onWrong();
  Future<void> playLessonComplete() => onLevelUp();
}

class DefaultSfxService implements SfxService {
  const DefaultSfxService({
    this.soundEnabled = true,
    this.hapticEnabled = true,
  });

  final bool soundEnabled;
  final bool hapticEnabled;

  @override
  Future<void> onCorrect({bool haptic = true}) async {
    if (haptic && hapticEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  @override
  Future<void> onWrong({bool haptic = true}) async {
    if (haptic && hapticEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  @override
  Future<void> onLevelUp({bool haptic = true}) async {
    if (haptic && hapticEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  @override
  Future<void> playCorrect() => onCorrect();

  @override
  Future<void> playWrong() => onWrong();

  @override
  Future<void> playLessonComplete() => onLevelUp();
}
