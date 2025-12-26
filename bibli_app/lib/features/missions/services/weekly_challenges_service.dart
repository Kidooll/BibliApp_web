import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';

class WeeklyChallengesService {
  final SupabaseClient _supabase;
  WeeklyChallengesService(this._supabase);

  Future<List<Map<String, dynamic>>> getActiveChallengesThisWeek() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final res = await _supabase
          .from('weekly_challenges')
          .select()
          .eq('is_active', true)
          .lte('start_date', today)
          .gte('end_date', today)
          .order('id');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserProgressThisWeek() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      final today = DateTime.now().toIso8601String().split('T')[0];

      final res = await _supabase
          .from('user_challenge_progress')
          .select(
            'id, challenge_id, current_progress, is_completed, completed_at, weekly_challenges(id, title, description, challenge_type, target_value, xp_reward, coin_reward, start_date, end_date)',
          )
          .eq('user_profile_id', user.id)
          .order('challenge_id');

      // Filtrar apenas desafios ativos na semana
      return List<Map<String, dynamic>>.from(res).where((row) {
        final ch = row['weekly_challenges'] as Map<String, dynamic>?;
        if (ch == null) return false;
        final start = (ch['start_date'] as String).substring(0, 10);
        final end = (ch['end_date'] as String).substring(0, 10);
        return start.compareTo(today) <= 0 && end.compareTo(today) >= 0;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> ensureUserChallengeRow(int challengeId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('user_challenge_progress').upsert({
        'user_profile_id': user.id,
        'challenge_id': challengeId,
        'current_progress': 0,
        'is_completed': false,
      });
    } catch (_) {}
  }

  Future<void> incrementByType(String challengeType, {int step = 1}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Buscar desafios ativos da semana por tipo
      final today = DateTime.now().toIso8601String().split('T')[0];
      final challenges = await _supabase
          .from('weekly_challenges')
          .select('id, target_value')
          .eq('is_active', true)
          .eq('challenge_type', challengeType)
          .lte('start_date', today)
          .gte('end_date', today);

      for (final ch in challenges) {
        await ensureUserChallengeRow(ch['id'] as int);
        final row = await _supabase
            .from('user_challenge_progress')
            .select('id, current_progress, is_completed')
            .eq('user_profile_id', user.id)
            .eq('challenge_id', ch['id'])
            .maybeSingle();
        if (row == null) continue;
        if (row['is_completed'] == true) continue;

        final newProgress = (row['current_progress'] as int? ?? 0) + step;
        final isCompleted = newProgress >= (ch['target_value'] as int? ?? 1);

        await _supabase
            .from('user_challenge_progress')
            .update({
              'current_progress': newProgress,
              'is_completed': isCompleted,
              if (isCompleted) 'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('id', row['id']);
      }
    } catch (_) {}
  }

  Future<bool> claimChallenge(int userChallengeProgressId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final row = await _supabase
          .from('user_challenge_progress')
          .select(
            'id, is_completed, challenge_id, weekly_challenges (title, xp_reward)',
          )
          .eq('id', userChallengeProgressId)
          .single();
      if (row['is_completed'] != true) return false;

      final ch = row['weekly_challenges'] as Map<String, dynamic>;
      final title = ch['title'] as String? ?? 'Desafio semanal';
      final xp = ch['xp_reward'] as int? ?? 0;

      // Evita múltiplos resgates do mesmo desafio (anti-farming)
      final alreadyClaimed = await _supabase
          .from('xp_transactions')
          .select('id')
          .eq('user_id', user.id)
          .eq('transaction_type', 'weekly_challenge')
          .eq('related_id', row['challenge_id'])
          .limit(1);
      if (alreadyClaimed.isNotEmpty) return false;

      if (xp > 0) {
        final ok = await GamificationService.addXp(
          actionName: 'weekly_challenge',
          xpAmount: xp,
          description: 'Desafio semanal: $title',
          relatedId: row['challenge_id'] as int?,
        );
        if (!ok) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyChallengesWithProgress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final today = DateTime.now().toIso8601String().split('T')[0];

      // 1) Desafios ativos nesta semana
      final active = await _supabase
          .from('weekly_challenges')
          .select()
          .eq('is_active', true)
          .lte('start_date', today)
          .gte('end_date', today)
          .order('id');

      // 2) Progresso do usuário (pode estar vazio)
      final progressRows = await _supabase
          .from('user_challenge_progress')
          .select(
            'id, challenge_id, current_progress, is_completed, completed_at',
          )
          .eq('user_profile_id', user.id);

      final Map<int, Map<String, dynamic>> challengeIdToProgress = {};
      for (final r in progressRows) {
        challengeIdToProgress[r['challenge_id'] as int] = r;
      }

      // 3) Mesclar e retornar
      final List<Map<String, dynamic>> result = [];
      for (final ch in active) {
        final chId = ch['id'] as int;
        final p = challengeIdToProgress[chId];
        result.add({
          // Quando há progresso, preserva o id da linha de progresso
          'id': p != null ? p['id'] : null,
          'challenge_id': chId,
          'current_progress': p != null ? (p['current_progress'] ?? 0) : 0,
          'is_completed': p != null ? (p['is_completed'] ?? false) : false,
          'completed_at': p != null ? p['completed_at'] : null,
          // Embutir dados do desafio
          'weekly_challenges': ch,
        });
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingChallenges() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final res = await _supabase
          .from('weekly_challenges')
          .select()
          .eq('is_active', true)
          .gt('start_date', today)
          .order('start_date');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentChallenges() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final res = await _supabase
          .from('weekly_challenges')
          .select()
          .eq('is_active', true)
          .lt('end_date', today)
          .order('end_date', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
