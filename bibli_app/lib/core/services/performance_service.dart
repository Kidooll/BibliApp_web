import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bibli_app/core/services/log_service.dart';

class PerformanceService {
  static final Map<String, DateTime> _timers = {};
  static final Map<String, int> _counters = {};

  static void startTimer(String name) {
    _timers[name] = DateTime.now();
  }

  static void endTimer(String name) {
    final startTime = _timers[name];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      LogService.info('Performance: $name took ${duration.inMilliseconds}ms', 'PerformanceService');
      _timers.remove(name);
    }
  }

  static void incrementCounter(String name) {
    _counters[name] = (_counters[name] ?? 0) + 1;
  }

  static void logCounter(String name) {
    final count = _counters[name] ?? 0;
    LogService.info('Performance: $name count: $count', 'PerformanceService');
  }

  static Future<T> measureAsync<T>(String name, Future<T> Function() operation) async {
    startTimer(name);
    try {
      final result = await operation();
      endTimer(name);
      return result;
    } catch (e) {
      endTimer(name);
      rethrow;
    }
  }

  static T measure<T>(String name, T Function() operation) {
    startTimer(name);
    try {
      final result = operation();
      endTimer(name);
      return result;
    } catch (e) {
      endTimer(name);
      rethrow;
    }
  }

  static void logMemoryUsage() {
    if (kDebugMode) {
      // Em debug, podemos logar uso de memória
      LogService.info('Memory usage check', 'PerformanceService');
    }
  }
}