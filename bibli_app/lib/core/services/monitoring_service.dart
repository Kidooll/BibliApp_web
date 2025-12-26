import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/services/log_service.dart';

class MonitoringService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Criar tabela de eventos se não existir
      await _createEventsTableIfNeeded();

      _initialized = true;
      LogService.info('MonitoringService inicializado', 'MonitoringService');
    } catch (e, stack) {
      LogService.error('Erro ao inicializar MonitoringService', e, stack, 'MonitoringService');
    }
  }

  static Future<void> _createEventsTableIfNeeded() async {
    try {
      // Verificar se tabela existe
      await Supabase.instance.client
          .from('app_events')
          .select('id')
          .limit(1);
    } catch (e) {
      // Tabela não existe, será criada via SQL no Supabase Dashboard
      LogService.info('Tabela app_events precisa ser criada no Supabase', 'MonitoringService');
    }
  }

  // Analytics Events (Supabase)
  static Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    if (!_initialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // evita 401 em web antes do login
      await Supabase.instance.client.from('app_events').insert({
        'user_id': user.id,
        'event_name': name,
        'event_data': parameters ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      LogService.warning('Erro ao logar evento: $name', 'MonitoringService');
    }
  }

  static Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {'screen_name': screenName});
  }

  static Future<void> logUserAction(String action, {Map<String, Object>? extra}) async {
    final params = <String, Object>{'action': action};
    if (extra != null) params.addAll(extra);
    await logEvent('user_action', params);
  }

  static Future<void> logPerformance(String operation, Duration duration) async {
    await logEvent('performance_metric', {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
    });
  }

  // Crash Reporting
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    if (!_initialized) return;

    LogService.error(
      'Erro capturado${context != null ? ' [$context]' : ''}',
      exception,
      stackTrace,
      'MonitoringService',
    );
    if (extra != null && extra.isNotEmpty) {
      LogService.debug('Extra: ${extra.toString()}', 'MonitoringService');
    }
  }

  static Future<void> setUserId(String userId) async {
    if (!_initialized) return;
  }

  static Future<void> setUserProperty(String name, String value) async {
    if (!_initialized) return;
  }

  // Métricas específicas do app
  static Future<void> logDevotionalRead(String devotionalId) async {
    await logEvent('devotional_read', {
      'devotional_id': devotionalId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> logMissionCompleted(String missionCode, int xpEarned) async {
    await logEvent('mission_completed', {
      'mission_code': missionCode,
      'xp_earned': xpEarned,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> logLevelUp(int newLevel, int totalXp) async {
    await logEvent('level_up', {
      'new_level': newLevel,
      'total_xp': totalXp,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> logStreakAchieved(int streakDays) async {
    await logEvent('streak_achieved', {
      'streak_days': streakDays,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> logQuoteShared(String quoteId) async {
    await logEvent('quote_shared', {
      'quote_id': quoteId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> logAppLaunch() async {
    await logEvent('app_launch', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> logAppBackground() async {
    await logEvent('app_background', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
