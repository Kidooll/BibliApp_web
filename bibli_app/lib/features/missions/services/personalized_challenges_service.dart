import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/services/log_service.dart';

class PersonalizedChallengesService {
  final SupabaseClient _supabase;

  PersonalizedChallengesService(this._supabase);

  /// Garante que usuário tem desafios personalizados ao fazer login
  Future<void> ensureUserChallenges(String userId) async {
    try {
      await _supabase.rpc('ensure_user_challenges', params: {'p_user_id': userId});
      LogService.info('Desafios personalizados gerados para usuário', 'PersonalizedChallengesService');
    } catch (e, stack) {
      LogService.error('Erro ao gerar desafios personalizados', e, stack, 'PersonalizedChallengesService');
    }
  }

  /// Busca desafios ativos do usuário
  Future<List<Map<String, dynamic>>> getUserChallenges(String userId) async {
    try {
      final response = await _supabase
          .from('user_weekly_challenges')
          .select('''
            *,
            weekly_challenges (
              title,
              description,
              challenge_type,
              target_value,
              xp_reward,
              week_start_date,
              week_end_date
            )
          ''')
          .eq('user_id', userId)
          .eq('is_completed', false)
          .order('created_at', ascending: false)
          .limit(3);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      LogService.error('Erro ao buscar desafios do usuário', e, stack, 'PersonalizedChallengesService');
      return [];
    }
  }

  /// Verifica se desafio foi reutilizado
  Future<bool> isChallengeReused(String challengeId) async {
    try {
      final response = await _supabase
          .from('weekly_challenges')
          .select('week_start_date')
          .eq('id', challengeId)
          .single();

      final weekStart = DateTime.parse(response['week_start_date']);
      final now = DateTime.now();
      final daysDiff = now.difference(weekStart).inDays;

      return daysDiff > 7; // Reutilizado se tem mais de 7 dias
    } catch (e) {
      return false;
    }
  }
}