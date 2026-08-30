import 'dart:developer' as dev;

import 'environment.dart';

class AppLogger {
  AppLogger._();

  static AppEnvironment _environment = AppEnvironment.development;

  static void init(AppEnvironment environment) {
    _environment = environment;
  }

  static void debug(String message, {String? tag, Object? error}) {
    if (_environment.isDevelopment) {
      dev.log(message, name: tag ?? 'Twilight', error: error);
    }
  }

  static void info(String message, {String? tag}) {
    dev.log(message, name: tag ?? 'Twilight');
  }

  static void warning(String message, {String? tag, Object? error}) {
    dev.log('[WARN] $message', name: tag ?? 'Twilight', error: error);
  }

  static void severe(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    dev.log('[ERROR] $message',
        name: tag ?? 'Twilight', error: error, stackTrace: stackTrace);
  }
}
