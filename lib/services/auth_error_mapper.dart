import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AuthErrorCategory {
  canceled,
  network,
  configuration,
  credentialConflict,
  requiresRecentLogin,
  userDisabled,
  unknown,
}

class AuthErrorResult {
  const AuthErrorResult({
    required this.category,
    required this.userMessage,
    this.isBenignCancel = false,
  });

  final AuthErrorCategory category;
  final String userMessage;
  final bool isBenignCancel;
}

/// Memetakan exception autentikasi (Google Sign-In / Firebase Auth) menjadi
/// pesan bahasa Indonesia yang ramah pengguna tanpa membocorkan detail teknis
/// seperti `PlatformException(sign_in_failed, t4: 10: ...)` ke antarmuka.
class AuthErrorMapper {
  const AuthErrorMapper._();

  static AuthErrorResult map(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[AuthErrorMapper] Raw auth error: $error');
      if (stackTrace != null) {
        debugPrint('[AuthErrorMapper] StackTrace: $stackTrace');
      }
    }

    if (error is PlatformException) {
      return _mapPlatformException(error);
    }

    if (error is FirebaseAuthException) {
      return _mapFirebaseAuthException(error);
    }

    if (error is StateError) {
      final msg = error.message.toLowerCase();
      if (msg.contains('dibatalkan') || msg.contains('cancel')) {
        return const AuthErrorResult(
          category: AuthErrorCategory.canceled,
          userMessage: 'Masuk dengan Google dibatalkan. Kamu tetap bisa belajar dalam Mode Tamu.',
          isBenignCancel: true,
        );
      }
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('sign_in_canceled') || raw.contains('12501')) {
      return const AuthErrorResult(
        category: AuthErrorCategory.canceled,
        userMessage: 'Masuk dengan Google dibatalkan. Kamu tetap bisa belajar dalam Mode Tamu.',
        isBenignCancel: true,
      );
    }
    if (raw.contains('network_error') ||
        raw.contains('network-request-failed') ||
        raw.contains('socketexception')) {
      return const AuthErrorResult(
        category: AuthErrorCategory.network,
        userMessage:
            'Koneksi internet terputus. Periksa jaringanmu lalu coba lagi.',
      );
    }
    if (raw.contains('sign_in_failed') ||
        raw.contains('apiException: 10'.toLowerCase()) ||
        raw.contains(' 10:') ||
        raw.contains('12500') ||
        raw.contains('developer_error')) {
      return const AuthErrorResult(
        category: AuthErrorCategory.configuration,
        userMessage: 'Layanan masuk Google belum dapat dihubungi pada perangkat ini. Progres belajarmu tetap tersimpan aman di perangkat (Mode Tamu).',
      );
    }

    return const AuthErrorResult(
      category: AuthErrorCategory.unknown,
      userMessage: 'Belum dapat masuk dengan Google saat ini. Progres belajarmu tetap aman di perangkat.',
    );
  }

  static String toUserMessage(Object error, [StackTrace? stackTrace]) {
    return map(error, stackTrace).userMessage;
  }

  static AuthErrorResult _mapPlatformException(PlatformException e) {
    final code = e.code.toLowerCase();
    final msg = (e.message ?? '').toLowerCase();
    final details = (e.details?.toString() ?? '').toLowerCase();
    final combined = '$code $msg $details';

    if (code == 'sign_in_canceled' || combined.contains('12501')) {
      return const AuthErrorResult(
        category: AuthErrorCategory.canceled,
        userMessage: 'Masuk dengan Google dibatalkan. Kamu tetap bisa belajar dalam Mode Tamu.',
        isBenignCancel: true,
      );
    }

    if (code == 'network_error' ||
        combined.contains('7:') ||
        combined.contains('network')) {
      return const AuthErrorResult(
        category: AuthErrorCategory.network,
        userMessage:
            'Koneksi internet terputus. Periksa jaringanmu lalu coba lagi.',
      );
    }

    if (code == 'sign_in_failed' ||
        combined.contains('10:') ||
        combined.contains('12500') ||
        combined.contains('developer_error')) {
      return const AuthErrorResult(
        category: AuthErrorCategory.configuration,
        userMessage: 'Layanan masuk Google belum dapat dihubungi pada perangkat ini. Progres belajarmu tetap tersimpan aman di perangkat (Mode Tamu).',
      );
    }

    return const AuthErrorResult(
      category: AuthErrorCategory.unknown,
      userMessage: 'Belum dapat masuk dengan Google saat ini. Progres belajarmu tetap aman di perangkat.',
    );
  }

  static AuthErrorResult _mapFirebaseAuthException(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    switch (code) {
      case 'network-request-failed':
        return const AuthErrorResult(
          category: AuthErrorCategory.network,
          userMessage:
              'Koneksi internet terputus. Periksa jaringanmu lalu coba lagi.',
        );
      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
      case 'provider-already-linked':
        return const AuthErrorResult(
          category: AuthErrorCategory.credentialConflict,
          userMessage: 'Akun Google ini sudah terdaftar. Menggabungkan progres belajarmu...',
        );
      case 'user-disabled':
        return const AuthErrorResult(
          category: AuthErrorCategory.userDisabled,
          userMessage: 'Akun ini telah dinonaktifkan. Kamu tetap bisa belajar dalam Mode Tamu.',
        );
      case 'requires-recent-login':
        return const AuthErrorResult(
          category: AuthErrorCategory.requiresRecentLogin,
          userMessage: 'Demi keamanan, silakan keluar lalu masuk kembali dengan Google sebelum menghapus akun.',
        );
      case 'canceled':
      case 'user-cancelled':
      case 'popup-closed-by-user':
        return const AuthErrorResult(
          category: AuthErrorCategory.canceled,
          userMessage: 'Masuk dengan Google dibatalkan. Kamu tetap bisa belajar dalam Mode Tamu.',
          isBenignCancel: true,
        );
      default:
        return const AuthErrorResult(
          category: AuthErrorCategory.unknown,
          userMessage: 'Belum dapat masuk dengan Google saat ini. Progres belajarmu tetap aman di perangkat.',
        );
    }
  }
}
