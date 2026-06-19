import 'dart:developer' as developer;

// the developer log gives us access to log our messages in better way print() <- which only appears in debugging mode not in production mode

class AppLogger {
  // we make a static _instace of our logger so it doesnot needs to be created every time
  // the _internal() constructor is private so it can only be called from within the class
  // it is a special
  static final AppLogger _instance = AppLogger._internal();

  // we initalize the logger
  AppLogger._internal();

  factory AppLogger() {
    return _instance;
  }

  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Standard print for guaranteed visibility in all consoles
    print(message);
    if (error != null) print("Error: $error");

    developer.log(
      message,
      name:
          'AppLogger', // This tag helps you filter your logs in Flutter DevTools
      level: _getLevelValue(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }

  void d(Object message) => _log('DEBUG', '🐛 [DEBUG] $message');
  void i(Object message) => _log('INFO', 'ℹ️ [INFO] $message');
  void w(Object message) => _log('WARN', '⚠️ [WARN] $message');

  void e(Object message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', '🚨 [ERROR] $message', error: error, stackTrace: stackTrace);
  }
}
