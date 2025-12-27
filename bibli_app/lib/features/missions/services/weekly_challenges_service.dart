import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

class WeeklyChallengesService {
  static const Map<String, List<String>> _challengeTypeAliases = {
    // Backward-compat: lreading foi typo antigo.
    ChallengeTypes.reading: [
      ChallengeTypes.reading,
      ChallengeTypes.legacyReadingTypo,
    ],
    ChallengeTypes.legacyReadingTypo: [
      ChallengeTypes.reading,
      ChallengeTypes.legacyReadingTypo,
    ],
    ChallengeTypes.sharing: [
      ChallengeTypes.sharing,
      ChallengeTypes.legacyShare,
    ],
    ChallengeTypes.legacyShare: [
      ChallengeTypes.sharing,
      ChallengeTypes.legacyShare,
    ],
    ChallengeTypes.devotionals: [
      ChallengeTypes.devotionals,
      ChallengeTypes.legacyDevotional,
    ],
    ChallengeTypes.legacyDevotional: [
      ChallengeTypes.devotionals,
      ChallengeTypes.legacyDevotional,
    ],
    ChallengeTypes.plan: [ChallengeTypes.plan],
    ChallengeTypes.study: [ChallengeTypes.study],
    ChallengeTypes.goal: [ChallengeTypes.goal],
  };

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
      final existing = await _supabase
          .from('user_challenge_progress')
          .select('id')
          .eq('user_profile_id', user.id)
          .eq('challenge_id', challengeId)
          .limit(1);
      if (existing.isNotEmpty) return;

      await _supabase.from('user_challenge_progress').insert({
        'user_profile_id': user.id,
        'challenge_id': challengeId,
        'current_progress': 0,
        'is_completed': false,
        'started_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> incrementByType(String challengeType, {int step = 1}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final types = _resolveChallengeTypes(challengeType);
      // Buscar desafios ativos da semana por tipo
      final today = DateTime.now().toIso8601String().split('T')[0];
      final baseQuery = _supabase
          .from('weekly_challenges')
          .select('id, target_value')
          .eq('is_active', true)
          .lte('start_date', today)
          .gte('end_date', today);
      final challenges = types.length == 1
          ? await baseQuery.eq('challenge_type', types.first)
          : await baseQuery.inFilter('challenge_type', types);

      for (final ch in challenges) {
        await ensureUserChallengeRow(ch['id'] as int);
        final rows = await _supabase
            .from('user_challenge_progress')
            .select('id, current_progress, is_completed')
            .eq('user_profile_id', user.id)
            .eq('challenge_id', ch['id'])
            .order('id', ascending: false)
            .limit(1);
        if (rows.isEmpty) continue;
        final row = rows.first;
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

  Future<void> updateGoalProgress({
    required int currentValue,
    required int goalTarget,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      if (goalTarget <= 0) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final challenges = await _supabase
          .from('weekly_challenges')
          .select('id')
          .eq('is_active', true)
          .eq('challenge_type', ChallengeTypes.goal)
          .lte('start_date', today)
          .gte('end_date', today);

      for (final ch in challenges) {
        final challengeId = ch['id'] as int?;
        if (challengeId == null) continue;
        await ensureUserChallengeRow(challengeId);
        final rows = await _supabase
            .from('user_challenge_progress')
            .select('id, current_progress, is_completed, completed_at')
            .eq('user_profile_id', user.id)
            .eq('challenge_id', challengeId)
            .order('id', ascending: false)
            .limit(1);
        if (rows.isEmpty) continue;
        final row = rows.first;
        final isCompleted = currentValue >= goalTarget;
        final updates = <String, dynamic>{
          'current_progress': currentValue,
          'is_completed': isCompleted,
        };
        if (isCompleted && row['is_completed'] != true) {
          updates['completed_at'] = DateTime.now().toIso8601String();
        }
        await _supabase
            .from('user_challenge_progress')
            .update(updates)
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
            'id, is_completed, challenge_id, weekly_challenges (title, xp_reward, coin_reward)',
          )
          .eq('id', userChallengeProgressId)
          .eq('user_profile_id', user.id)
          .maybeSingle();
      if (row == null) return false;
      if (row['is_completed'] != true) return false;

      final ch = row['weekly_challenges'] as Map<String, dynamic>;
      final title = ch['title'] as String? ?? 'Desafio semanal';
      final xp = ch['xp_reward'] as int? ?? 0;
      final coin = ch['coin_reward'] as int? ?? 0;

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
      } else {
        await _supabase.from('xp_transactions').insert({
          'user_id': user.id,
          'xp_amount': 0,
          'transaction_type': 'weekly_challenge',
          'description': 'Desafio semanal: $title',
          'related_id': row['challenge_id'] as int?,
        });
      }

      if (coin > 0) {
        final profile = await _supabase
            .from('user_profiles')
            .select('coins')
            .eq('id', user.id)
            .maybeSingle();
        final currentCoins = (profile?['coins'] as int?) ?? 0;
        await _supabase.from('user_profiles').update({
          'coins': currentCoins + coin,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  List<String> _resolveChallengeTypes(String challengeType) {
    final normalized = challengeType.trim().toLowerCase();
    return _challengeTypeAliases[normalized] ?? [normalized];
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

  void _applyGoalTarget(Map<String, dynamic> challenge, int? weeklyGoal) {
    if (weeklyGoal == null) return;
    if ((challenge['challenge_type'] as String?) != ChallengeTypes.goal) return;
    challenge['target_value'] = weeklyGoal;
  }

  Future<List<Map<String, dynamic>>> getWeeklyChallengesWithProgress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final today = DateTime.now().toIso8601String().split('T')[0];
      final weeklyGoal = await _fetchWeeklyGoal(user.id);

      // 1) Desafios ativos nesta semana
      final active = await _supabase
          .from('weekly_challenges')
          .select()
          .eq('is_active', true)
          .lte('start_date', today)
          .gte('end_date', today)
          .order('id');
      final activeIds = active.map((row) => row['id'] as int).toList();

      final claimedRows = await _supabase
          .from('xp_transactions')
          .select('related_id, created_at')
          .eq('user_id', user.id)
          .eq('transaction_type', 'weekly_challenge');
      final claimedMap = <int, String>{};
      for (final row in claimedRows) {
        final id = row['related_id'];
        if (id is int && activeIds.contains(id)) {
          claimedMap[id] = row['created_at']?.toString() ?? '';
        }
      }

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
        _applyGoalTarget(ch, weeklyGoal);
        final chId = ch['id'] as int;
        final p = challengeIdToProgress[chId];
        result.add({
          // Quando há progresso, preserva o id da linha de progresso
          'id': p != null ? p['id'] : null,
          'challenge_id': chId,
          'current_progress': p != null ? (p['current_progress'] ?? 0) : 0,
          'is_completed': p != null ? (p['is_completed'] ?? false) : false,
          'completed_at': p != null ? p['completed_at'] : null,
          'is_claimed': claimedMap.containsKey(chId),
          'claimed_at': claimedMap[chId],
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
