import 'package:flutter/foundation.dart';

class LogService {
  static void error(
    String message,
    dynamic error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final ctx = context != null ? '[$context] ' : '';
    debugPrint('❌ $ctx$message');
    if (error != null) debugPrint('   Error: $error');
    if (stackTrace != null) debugPrint('   Stack: $stackTrace');
  }

  static void warning(String message, [String? context]) {
    final ctx = context != null ? '[$context] ' : '';
    debugPrint('⚠️  $ctx$message');
  }

  static void info(String message, [String? context]) {
    final ctx = context != null ? '[$context] ' : '';
    debugPrint('ℹ️  $ctx$message');
  }

  static void debug(String message, [String? context]) {
    final ctx = context != null ? '[$context] ' : '';
    debugPrint('🔍 $ctx$message');
  }
}
