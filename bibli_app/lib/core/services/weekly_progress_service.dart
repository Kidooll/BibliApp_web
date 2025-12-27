import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/core/services/server_time_service.dart';
import 'package:bibli_app/features/missions/services/weekly_challenges_service.dart';

class WeeklyProgressService {
  final SupabaseClient _supabase;

  WeeklyProgressService(this._supabase);

  Future<void> incrementDevotionalsRead({int step = 1}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final todayStr =
          await ServerTimeService.getSaoPauloDate(_supabase) ??
              DateTime.now().toIso8601String().split('T').first;
      final today = _parseDate(todayStr);
      if (today == null) return;

      final weekStart = _startOfWeek(today);
      final weekStartStr = _formatDate(weekStart);
      final now = DateTime.now().toIso8601String();

      final existing = await _supabase
          .from('weekly_progress')
          .select('id, devotionals_read_this_week')
          .eq('user_profile_id', user.id)
          .eq('week_start_date', weekStartStr)
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existing == null) {
        final weeklyGoal = await _fetchWeeklyGoal(user.id);
        await _supabase.from('weekly_progress').insert({
          'user_profile_id': user.id,
          'week_start_date': weekStartStr,
          'devotionals_read_this_week': step,
          'created_at': now,
          'updated_at': now,
        });
        if (weeklyGoal != null) {
          await _updateGoalProgress(step, weeklyGoal);
        }
        return;
      }

      final current = (existing['devotionals_read_this_week'] as int?) ?? 0;
      final weeklyGoal = await _fetchWeeklyGoal(user.id);
      final newCount = current + step;
      await _supabase.from('weekly_progress').update({
        'devotionals_read_this_week': newCount,
        'updated_at': now,
      }).eq('id', existing['id']);
      if (weeklyGoal != null) {
        await _updateGoalProgress(newCount, weeklyGoal);
      }
    } catch (e, stack) {
      LogService.error('Erro ao atualizar weekly_progress', e, stack, 'WeeklyProgressService');
    }
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _startOfWeek(DateTime date) {
    // Semana inicia no domingo.
    return date.subtract(Duration(days: date.weekday % 7));
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<int?> _fetchWeeklyGoal(String userId) async {
    try {
      final profile = await _supabase
          .from('user_profiles')
          .select('weekly_goal')
          .eq('id', userId)
          .maybeSingle();
      final goal = (profile?['weekly_goal'] as int?) ?? 0;
      if (goal <= 0) return null;
      return goal;
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateGoalProgress(int currentValue, int weeklyGoal) async {
    try {
      await WeeklyChallengesService(_supabase).updateGoalProgress(
        currentValue: currentValue,
        goalTarget: weeklyGoal,
      );
    } catch (e, stack) {
      LogService.error(
        'Erro ao atualizar desafio semanal (goal)',
        e,
        stack,
        'WeeklyProgressService',
      );
    }
  }
}
