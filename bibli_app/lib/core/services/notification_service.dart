import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Serviço simples para notificações locais (Android).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _legacyReadingReminderId = 1001;
  static const int _reminderIdBase = 1100;
  static bool _initialized = false;

  /// Inicializa o plugin e agenda os lembretes conforme preferências.
  static Future<void> initAndScheduleDailyReading() async {
    try {
      await _ensureInitialized();
      await scheduleFromPreferences().timeout(const Duration(seconds: 3));
    } catch (e) {
      // Falha silenciosa - notificações não são críticas
      _initialized = false;
    }
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidInit),
      ).timeout(const Duration(seconds: 5));

      _initialized = true;
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Agenda lembretes respeitando horário e dias configurados.
  static Future<void> scheduleFromPreferences() async {
    await _ensureInitialized();
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    final configured = prefs.getBool('reminder_configured') ?? false;
    final skipped = prefs.getBool('reminder_skipped') ?? false;

    if (!notificationsEnabled || !configured || skipped) {
      await cancelDailyReadingReminder();
      return;
    }

    final time = _readReminderTime(prefs);
    final weekdays = _readSelectedWeekdays(prefs);
    final days = weekdays.isEmpty ? _allWeekdays : weekdays;

    await _scheduleForWeekdays(days, time);
  }

  static TimeOfDay _readReminderTime(SharedPreferences prefs) {
    final hour = prefs.getInt('reminder_hour');
    final minute = prefs.getInt('reminder_minute');
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }

    const fallback = ReminderDefaults.time;
    final formatted = prefs.getString('reminder_time') ?? '';
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(formatted);
    if (match == null) {
      return fallback;
    }

    var parsedHour = int.tryParse(match.group(1) ?? '');
    final parsedMinute = int.tryParse(match.group(2) ?? '');
    if (parsedHour == null || parsedMinute == null) {
      return fallback;
    }

    final lower = formatted.toLowerCase();
    if (lower.contains('pm') && parsedHour < 12) {
      parsedHour += 12;
    } else if (lower.contains('am') && parsedHour == 12) {
      parsedHour = 0;
    }

    if (parsedHour < 0 || parsedHour > 23 || parsedMinute < 0 || parsedMinute > 59) {
      return fallback;
    }

    return TimeOfDay(hour: parsedHour, minute: parsedMinute);
  }

  static List<int> _readSelectedWeekdays(SharedPreferences prefs) {
    final flags = prefs.getStringList('reminder_days') ?? const <String>[];
    final selected = <int>[];
    for (var i = 0; i < flags.length && i < _allWeekdays.length; i += 1) {
      if (flags[i] == '1') {
        selected.add(_allWeekdays[i]);
      }
    }
    return selected;
  }

  static Future<void> _scheduleForWeekdays(
    List<int> weekdays,
    TimeOfDay time,
  ) async {
    await cancelDailyReadingReminder();

    const androidDetails = AndroidNotificationDetails(
      'reading_reminder',
      'Lembretes de leitura',
      channelDescription: 'Notificações para lembrar da leitura diária',
      importance: Importance.high,
      priority: Priority.high,
    );

    for (final weekday in weekdays) {
      final scheduled = _nextInstanceOfWeekdayTime(
        weekday,
        time.hour,
        time.minute,
      );
      final id = _reminderIdBase + weekday;
      await _plugin.zonedSchedule(
        id,
        'Hora da leitura',
        'Separe alguns minutos para sua leitura diária.',
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(
    int weekday,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Cancela o lembrete diário.
  static Future<void> cancelDailyReadingReminder() async {
    await _plugin.cancel(_legacyReadingReminderId);
    for (var day = 1; day <= 7; day += 1) {
      await _plugin.cancel(_reminderIdBase + day);
    }
  }
}

const List<int> _allWeekdays = [
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
];
