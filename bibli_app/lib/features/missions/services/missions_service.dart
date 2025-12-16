import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';

class MissionsService {
  final SupabaseClient _supabase;
  MissionsService(this._supabase);

  Future<void> prepareTodayMissions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Buscar missões ativas
      final missions = await _supabase
          .from('daily_missions')
          .select()
          .eq('is_active', true);

      final today = _todayDate();

      // Garantir um registro em user_missions para cada missão ativa hoje
      for (final m in missions) {
        await _supabase.from('user_missions').upsert({
          'user_id': user.id,
          'mission_id': m['id'],
          'mission_date': today,
          'target': 1,
        }, onConflict: 'user_id,mission_id,mission_date');
      }
    } catch (_) {
      // Tabelas ainda não existem ou outro erro: ignorar silenciosamente
    }
  }

  Future<List<Map<String, dynamic>>> getTodayMissions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final today = _todayDate();

      final response = await _supabase
          .from('user_missions')
          .select(
            'id, mission_id, mission_date, progress, target, status, daily_missions(id, code, title, description, xp_reward, coin_reward)',
          )
          .eq('user_id', user.id)
          .eq('mission_date', today)
          .order('mission_id');

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<bool> claimMission(int userMissionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Buscar missão do usuário com join para pegar xp_reward
      final record = await _supabase
          .from('user_missions')
          .select('id, status, mission_id, daily_missions (title, xp_reward)')
          .eq('id', userMissionId)
          .single();
      if (record['status'] == 'claimed') return false; // já resgatada
      if (record['status'] != 'completed') {
        return false; // só pode resgatar se concluída
      }

      final mission = record['daily_missions'];
      final xpReward = mission['xp_reward'] as int? ?? 0;
      final title = mission['title'] as String? ?? 'Missão diária';

      // Atualiza status para claimed
      await _supabase
          .from('user_missions')
          .update({
            'status': 'claimed',
            'claimed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userMissionId)
          .eq('status', 'completed'); // garante transição válida

      // Concede XP
      if (xpReward > 0) {
        await GamificationService.addXp(
          actionName: 'mission_claimed',
          xpAmount: xpReward,
          description: 'Missão diária: $title',
          relatedId: record['mission_id'] as int?,
        );
        await GamificationService.forceSync();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _ensureTodayMissionByCode(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final today = _todayDate();

    final mission = await _supabase
        .from('daily_missions')
        .select('id')
        .eq('code', code)
        .maybeSingle();
    if (mission == null) return;

    await _supabase.from('user_missions').upsert({
      'user_id': user.id,
      'mission_id': mission['id'],
      'mission_date': today,
    }, onConflict: 'user_id,mission_id,mission_date');
  }

  Future<void> completeMissionByCode(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final today = _todayDate();

    await _ensureTodayMissionByCode(code);

    final mission = await _supabase
        .from('daily_missions')
        .select('id, xp_reward, title')
        .eq('code', code)
        .single();

    // Não alterar se já foi resgatada
    final existing = await _supabase
        .from('user_missions')
        .select('id, status')
        .eq('user_id', user.id)
        .eq('mission_id', mission['id'])
        .eq('mission_date', today)
        .single();
    if (existing['status'] == 'claimed') return;

    // Marca como concluída e já registra como resgatada para evitar double-claim
    await _supabase
        .from('user_missions')
        .update({
          'status': 'claimed',
          'completed_at': DateTime.now().toIso8601String(),
          'claimed_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id)
        .eq('mission_id', mission['id'])
        .eq('mission_date', today);

    final xpReward = mission['xp_reward'] as int? ?? 0;
    if (xpReward > 0) {
      await GamificationService.addXp(
        actionName: 'mission_claimed',
        xpAmount: xpReward,
        description: 'Missão diária: ${mission['title'] ?? code}',
        relatedId: mission['id'] as int?,
      );
      await GamificationService.forceSync();
    }
  }

  Future<void> incrementMissionByCode(String code, {int step = 1}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final today = _todayDate();

    await _ensureTodayMissionByCode(code);

    final mission = await _supabase
        .from('daily_missions')
        .select('id')
        .eq('code', code)
        .single();

    final row = await _supabase
        .from('user_missions')
        .select('id, progress, target, status')
        .eq('user_id', user.id)
        .eq('mission_id', mission['id'])
        .eq('mission_date', today)
        .single();

    if (row['status'] == 'claimed') return;

    final newProgress = (row['progress'] as int? ?? 0) + step;
    final target = row['target'] as int? ?? 1;
    final isCompleted = newProgress >= target;

    await _supabase
        .from('user_missions')
        .update({
          'progress': newProgress,
          'status': isCompleted ? 'completed' : 'pending',
          if (isCompleted) 'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', row['id']);
  }

  String _todayDate() {
    return DateTime.now().toUtc().toIso8601String().split('T')[0];
  }
}
