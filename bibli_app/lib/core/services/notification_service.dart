import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Serviço simples para notificações locais (Android).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _readingReminderId = 1001;
  static bool _initialized = false;

  /// Inicializa o plugin e agenda o lembrete diário de leitura (08:00).
  static Future<void> initAndScheduleDailyReading() async {
    if (_initialized) return;
    
    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidInit),
      ).timeout(const Duration(seconds: 5));

      _initialized = true;
      await scheduleDailyReadingReminder().timeout(const Duration(seconds: 3));
    } catch (e) {
      // Falha silenciosa - notificações não são críticas
      _initialized = false;
    }
  }

  /// Agenda um lembrete diário às 08:00 horário local.
  static Future<void> scheduleDailyReadingReminder() async {
    if (!_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'reading_reminder',
        'Lembretes de leitura',
        channelDescription: 'Notificações para lembrar da leitura diária',
        importance: Importance.high,
        priority: Priority.high,
      );

      final now = tz.TZDateTime.now(tz.local);
      final scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8,
        0,
      ).add(now.isAfter(
              tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0))
          ? const Duration(days: 1)
          : Duration.zero);

      await _plugin.zonedSchedule(
        _readingReminderId,
        'Hora da leitura',
        'Separe alguns minutos para sua leitura diária.',
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Cancela o lembrete diário.
  static Future<void> cancelDailyReadingReminder() async {
    await _plugin.cancel(_readingReminderId);
  }
}
