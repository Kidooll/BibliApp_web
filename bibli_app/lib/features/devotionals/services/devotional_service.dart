import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/devotionals/models/devotional.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:bibli_app/features/missions/services/missions_service.dart';
import 'package:bibli_app/features/missions/services/weekly_challenges_service.dart';
import 'package:bibli_app/core/services/log_service.dart';

class DevotionalService {
  final SupabaseClient _supabase;

  DevotionalService(this._supabase);

  /// Busca o devocional do dia atual
  Future<Devotional?> getTodaysDevotional() async {
    try {
      final today = DateTime.now();
      final response = await _supabase
          .from('devotionals')
          .select()
          .eq('published_date', today.toIso8601String().split('T')[0])
          .single();

      return Devotional.fromJson(response);
    } catch (e, stack) {
      LogService.error('Erro ao buscar devocional do dia', e, stack, 'DevotionalService');
      return null;
    }
  }

  /// Busca um devocional específico por ID
  Future<Devotional?> getDevotionalById(int id) async {
    try {
      final response = await _supabase
          .from('devotionals')
          .select()
          .eq('id', id)
          .single();

      return Devotional.fromJson(response);
    } catch (e, stack) {
      LogService.error('Erro ao buscar devocional por ID', e, stack, 'DevotionalService');
      return null;
    }
  }

  /// Busca devocionais recentes
  Future<List<Devotional>> getRecentDevotionals({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('devotionals')
          .select()
          .order('published_date', ascending: false)
          .limit(limit);

      return response.map((json) => Devotional.fromJson(json)).toList();
    } catch (e, stack) {
      LogService.error('Erro ao buscar devocionais recentes', e, stack, 'DevotionalService');
      return [];
    }
  }

  /// Marca um devocional como lido
  Future<bool> markAsRead(int devotionalId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Verificar se já foi lido hoje
      final todayUtc = DateTime.now().toUtc().toIso8601String().split('T')[0];
      final alreadyRead = await _hasReadToday(devotionalId, user.id, todayUtc);
      final firstReadOfDay =
          !(await _hasAnyDevotionalReadToday(user.id, todayUtc));

      if (alreadyRead) {
        LogService.info('Devocional já lido hoje: $devotionalId', 'DevotionalService');
        return false;
      }

      // Inserir registro de leitura
      final readAt = DateTime.now().toUtc().toIso8601String();
      try {
        await _supabase.from('read_devotionals').insert({
          'devotional_id': devotionalId,
          'user_profile_id': user.id,
          'read_at': readAt,
          'read_date': todayUtc,
        });
        
        // Adicionar em reading_history para o calendário
        await _supabase.from('reading_history').insert({
          'user_id': user.id,
          'devotional_id': devotionalId,
          'read_at': readAt,
          'read_date': DateTime.now().toIso8601String().split('T')[0],
        });
      } on PostgrestException catch (e) {
        // Tratamento de unicidade (unique_violation)
        if (e.code == '23505') {
          LogService.info('Devocional já lido (constraint)', 'DevotionalService');
          return false;
        }
        rethrow;
      }

      // Integrar com sistema de gamificação (só se não foi lido hoje)
      await GamificationService.markDevotionalAsRead(
        devotionalId,
        firstReadOfDay: firstReadOfDay,
      );

      // Completar missão diária: ler devocional de hoje
      try {
        final missions = MissionsService(_supabase);
        await missions.completeMissionByCode('read_today_devotional');
      } catch (e, stack) {
        LogService.error('Erro ao completar missão', e, stack, 'DevotionalService');
      }

      // Incrementar desafios semanais (reading)
      try {
        final weekly = WeeklyChallengesService(_supabase);
        await weekly.incrementByType('reading', step: 1);
      } catch (e, stack) {
        LogService.error('Erro ao incrementar desafio', e, stack, 'DevotionalService');
      }

      LogService.info('Devocional marcado como lido: $devotionalId', 'DevotionalService');
      return true;
    } catch (e, stack) {
      LogService.error('Erro ao marcar devocional', e, stack, 'DevotionalService');
      return false;
    }
  }

  Future<bool> _hasAnyDevotionalReadToday(String userId, String today) async {
    try {
      final res = await _supabase
          .from('read_devotionals')
          .select('id')
          .eq('user_profile_id', userId)
          .eq('read_date', today)
          .limit(1);
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se o devocional já foi lido hoje
  Future<bool> _hasReadToday(
    int devotionalId,
    String userId,
    String today,
  ) async {
    try {
      final response = await _supabase
          .from('read_devotionals')
          .select('id')
          .eq('devotional_id', devotionalId)
          .eq('user_profile_id', userId)
          .eq('read_date', today)
          .maybeSingle();

      return response != null;
    } catch (e, stack) {
      LogService.error('Erro ao verificar leitura', e, stack, 'DevotionalService');
      return false;
    }
  }
}
