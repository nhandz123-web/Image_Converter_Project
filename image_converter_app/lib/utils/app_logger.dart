import 'package:flutter/foundation.dart';

/// Utility class cho logging trong app
/// Chỉ print log khi ở chế độ debug, production sẽ không print
/// 
/// Sử dụng:
/// ```dart
/// AppLogger.d('Debug message');      // Debug
/// AppLogger.i('Info message');       // Info  
/// AppLogger.w('Warning message');    // Warning
/// AppLogger.e('Error message');      // Error
/// ```
class AppLogger {
  // Prefix icons cho các log levels
  static const String _debugIcon = '🐛';
  static const String _infoIcon = '💡';
  static const String _warningIcon = '⚠️';
  static const String _errorIcon = '❌';
  static const String _successIcon = '✅';
  static const String _networkIcon = '🌐';
  static const String _cacheIcon = '📦';
  
  /// Debug log - Thông tin debug chi tiết
  static void d(String message, {String? tag}) {
    _log(_debugIcon, 'DEBUG', message, tag: tag);
  }
  
  /// Info log - Thông tin thông thường
  static void i(String message, {String? tag}) {
    _log(_infoIcon, 'INFO', message, tag: tag);
  }
  
  /// Warning log - Cảnh báo
  static void w(String message, {String? tag}) {
    _log(_warningIcon, 'WARN', message, tag: tag);
  }
  
  /// Error log - Lỗi
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_errorIcon, 'ERROR', message, tag: tag);
    if (error != null) {
      _log(_errorIcon, 'ERROR', 'Exception: $error', tag: tag);
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('📍 StackTrace: $stackTrace');
    }
  }
  
  /// Success log - Thành công
  static void success(String message, {String? tag}) {
    _log(_successIcon, 'SUCCESS', message, tag: tag);
  }
  
  /// Network log - API calls
  static void network(String message, {String? tag}) {
    _log(_networkIcon, 'NETWORK', message, tag: tag);
  }
  
  /// Cache log - Cache operations
  static void cache(String message, {String? tag}) {
    _log(_cacheIcon, 'CACHE', message, tag: tag);
  }
  
  /// Internal log method
  static void _log(String icon, String level, String message, {String? tag}) {
    // Chỉ log trong debug mode
    if (kDebugMode) {
      final tagPart = tag != null ? '[$tag] ' : '';
      debugPrint('$icon $tagPart$message');
    }
    
    // TODO: Trong production, có thể gửi errors lên Firebase Crashlytics hoặc Sentry
    // if (!kDebugMode && level == 'ERROR') {
    //   FirebaseCrashlytics.instance.log(message);
    // }
  }
  
  /// Log API request
  static void apiRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      debugPrint('🚀 [$method] $url');
      if (body != null) {
        debugPrint('📤 Body: $body');
      }
    }
  }
  
  /// Log API response
  static void apiResponse(int statusCode, String url, {dynamic data}) {
    if (kDebugMode) {
      final icon = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      debugPrint('$icon [$statusCode] $url');
    }
  }
}
