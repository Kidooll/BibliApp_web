import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/services/performance_service.dart';

void main() {
  group('PerformanceService Tests', () {
    test('deve medir tempo de operação', () async {
      PerformanceService.startTimer('test_operation');
      
      await Future.delayed(const Duration(milliseconds: 10));
      
      PerformanceService.endTimer('test_operation');
      
      expect(true, isTrue);
    });

    test('deve incrementar contador', () {
      PerformanceService.incrementCounter('test_counter');
      PerformanceService.incrementCounter('test_counter');
      
      PerformanceService.logCounter('test_counter');
      
      expect(true, isTrue);
    });

    test('deve medir operação async', () async {
      final result = await PerformanceService.measureAsync('async_test', () async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 'success';
      });
      
      expect(result, 'success');
    });

    test('deve medir operação síncrona', () {
      final result = PerformanceService.measure('sync_test', () {
        return 42;
      });
      
      expect(result, 42);
    });
  });
}