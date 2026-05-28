import 'package:logger/logger.dart';

/// AppLogger encapsulates the 'logger' package to provide beautiful,
/// color-coded, structured logs for Web and Mobile target platforms.
///
/// Avoid using `print` directly; instead, invoke [AppLogger.d], [AppLogger.e], etc.
class AppLogger {
  // Configured with standard formatting, showing time and no stacktrace for simple logs
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 80, // Width of the output
      colors: true, // Colorful log messages (works in terminal/IDE consoles)
      printEmojis: true, // Print emojis for log levels
      printTime: true, // Should each log print contain a timestamp
    ),
  );

  /// Verbose/Trace level logging - useful for highly repetitive logs (e.g. build ticks, sensor polling)
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Debug level logging - for information helpful during development
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info level logging - for significant high-level flow (e.g. App initialization complete)
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning level logging - for unexpected behavior that won't crash the app
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error level logging - for severe failures, always logs stacktraces when available
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Critical/WTF level logging - for failures that represent severe architectural assumptions violated
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
