import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/devotionals/models/devotional.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:bibli_app/features/missions/services/missions_service.dart';
import 'package:bibli_app/features/missions/services/weekly_challenges_service.dart';

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
    } catch (e) {
      print('Erro ao buscar devocional do dia: $e');
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
    } catch (e) {
      print('Erro ao buscar devocional por ID: $e');
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
    } catch (e) {
      print('Erro ao buscar devocionais recentes: $e');
      return [];
    }
  }

  /// Marca um devocional como lido
  Future<bool> markAsRead(int devotionalId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Verificar se já foi lido hoje
      final today = DateTime.now().toIso8601String().split('T')[0];
      final alreadyRead = await _hasReadToday(devotionalId, user.id, today);

      if (alreadyRead) {
        print(
          'Devocional já foi lido hoje: $devotionalId - Não será marcado novamente',
        );
        return false;
      }

      // Inserir registro de leitura
      try {
        await _supabase.from('read_devotionals').insert({
          'devotional_id': devotionalId,
          'user_profile_id': user.id,
          'read_at': DateTime.now().toIso8601String(),
        });
      } on PostgrestException catch (e) {
        // Tratamento de unicidade (unique_violation)
        if (e.code == '23505') {
          print(
            'Devocional já lido hoje (único por dia) capturado pelo banco: $devotionalId',
          );
          return false;
        }
        rethrow;
      }

      // Integrar com sistema de gamificação (só se não foi lido hoje)
      await GamificationService.markDevotionalAsRead(devotionalId);

      // Completar missão diária: ler devocional de hoje
      try {
        final missions = MissionsService(_supabase);
        await missions.completeMissionByCode('read_today_devotional');
      } catch (_) {}

      // Incrementar desafios semanais (reading)
      try {
        final weekly = WeeklyChallengesService(_supabase);
        await weekly.incrementByType('reading', step: 1);
      } catch (_) {}

      print('Devocional marcado como lido com sucesso: $devotionalId');
      return true;
    } catch (e) {
      print('Erro ao marcar devocional como lido: $e');
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
          .select('read_at')
          .eq('devotional_id', devotionalId)
          .eq('user_profile_id', userId)
          .gte('read_at', '$today 00:00:00')
          .lte('read_at', '$today 23:59:59')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Erro ao verificar se devocional foi lido hoje: $e');
      return false;
    }
  }
}
