import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static void info(String message, {String name = 'KATARA'}) {
    developer.log(message, name: name);
  }

  static void warning(String message, {String name = 'KATARA', Object? error}) {
    developer.log(message, name: name, level: 900, error: error);
  }

  static void error(
    String message, {
    String name = 'KATARA',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
