import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level.dart';
import '../models/achievement.dart';
import '../models/user_stats.dart';

class GamificationService {
  static const String _supabase = 'supabase';
  static const String _cacheKey = 'gamification_cache';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Event bus simples para notificar mudanças (ex.: XP atualizado)
  static final StreamController<String> _eventController =
      StreamController<String>.broadcast();
  static Stream<String> get events => _eventController.stream;
  static void _emitEvent(String name) {
    if (!_eventController.isClosed) {
      _eventController.add(name);
    }
  }

  // Cache local
  static Map<String, dynamic> _localCache = {};
  static DateTime? _lastSync;

  // Singleton
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  // Inicializar cache
  static Future<void> initialize() async {
    await _loadCache();
  }

  // Carregar cache local
  static Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey);
      final lastSyncData = prefs.getString(_lastSyncKey);

      if (cacheData != null) {
        _localCache = json.decode(cacheData);
      }

      if (lastSyncData != null) {
        _lastSync = DateTime.parse(lastSyncData);
      }
    } catch (e) {
      print('Erro ao carregar cache: $e');
      _localCache = {};
    }
  }

  // Salvar cache local
  static Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_localCache));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Erro ao salvar cache: $e');
    }
  }

  // Sincronizar com Supabase quando necessário
  static Future<void> _syncIfNeeded() async {
    final now = DateTime.now();
    if (_lastSync == null || now.difference(_lastSync!).inMinutes > 5) {
      await _syncWithSupabase();
    }
  }

  // Sincronizar com Supabase
  static Future<void> _syncWithSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Buscar dados do usuário
      final userStats = await _getUserStatsFromSupabase(user.id);
      final achievements = await _getUserAchievementsFromSupabase(user.id);
      final totalXp = await _getUserTotalXpFromSupabase(user.id);

      // Atualizar cache
      _localCache['user_stats'] = userStats?.toJson();
      _localCache['achievements'] = achievements
          .map((a) => a.toJson())
          .toList();
      _localCache['total_xp'] = totalXp;
      _lastSync = DateTime.now();

      await _saveCache();
    } catch (e) {
      print('Erro ao sincronizar com Supabase: $e');
    }
  }

  // Adicionar XP ao usuário
  static Future<bool> addXp({
    required String actionName,
    required int xpAmount,
    String? description,
    int? relatedId,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final previousTotalXp = await getTotalXp();
      final previousLevel = _levelForXp(previousTotalXp);

      await Supabase.instance.client
          .from('xp_transactions')
          .insert({
            'user_id': user.id,
            'xp_amount': xpAmount,
            'transaction_type': actionName,
            'description': description,
            'related_id': relatedId,
          })
          .select()
          .single();

      // Atualizar cache local imediato
      final currentXp = previousTotalXp;
      final updatedXp = currentXp + xpAmount;
      _localCache['total_xp'] = updatedXp;

      // Verificar se subiu de nível (com base no delta de XP)
      final newLevel = _levelForXp(updatedXp);

      if (newLevel > previousLevel) {
        print('🎉 Level up! Novo nível: $newLevel');
        _emitEvent('level_up');
      }

      // Verificar conquistas
      await _checkAchievements();

      // Sincronizar com Supabase para refletir no restante da UI
      await _syncWithSupabase();
      await _saveCache();

      // Notificar que XP mudou
      _emitEvent('xp_changed');
      return true;
    } on PostgrestException catch (e) {
      print(
        'Erro ao inserir XP: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      return false;
    } catch (e) {
      print('Erro ao adicionar XP: $e');
      return false;
    }
  }

  // Marcar devocional como lido
  static Future<void> markDevotionalAsRead(int devotionalId) async {
    try {
      await _syncIfNeeded();

      // Verificar se já leu este devocional hoje
      final today = DateTime.now().toIso8601String().split('T')[0];
      final alreadyReadToday = await _hasReadDevotionalToday(
        devotionalId,
        today,
      );

      if (alreadyReadToday) {
        print(
          'Devocional já lido hoje: $devotionalId - Streak não será atualizada',
        );
        return;
      }

      // Verificar se já leu algum devocional hoje (para daily bonus)
      final hasReadAnyDevotionalToday = await _hasReadAnyDevotionalToday(today);

      // Adicionar XP por ler devocional
      await addXp(
        actionName: 'devotional_read',
        xpAmount: 8,
        description: 'Devocional lido',
        relatedId: devotionalId,
      );

      // Verificar se é primeira leitura do dia (qualquer devocional)
      if (!hasReadAnyDevotionalToday) {
        await addXp(
          actionName: 'daily_bonus',
          xpAmount: 5,
          description: 'Primeira leitura do dia',
        );
      }

      // Atualizar streak (só se não leu hoje)
      await _updateStreak();

      await _saveCache();
    } catch (e) {
      print('Erro ao marcar devocional como lido: $e');
    }
  }

  // Verificar se o usuário já leu este devocional hoje
  static Future<bool> _hasReadDevotionalToday(
    int devotionalId,
    String today,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final response = await Supabase.instance.client
          .from('read_devotionals')
          .select('read_at')
          .eq('devotional_id', devotionalId)
          .eq('user_profile_id', user.id)
          .gte('read_at', '$today 00:00:00')
          .lte('read_at', '$today 23:59:59')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Erro ao verificar se devocional foi lido hoje: $e');
      return false;
    }
  }

  // Verificar se o usuário já leu algum devocional hoje
  static Future<bool> _hasReadAnyDevotionalToday(String today) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final response = await Supabase.instance.client
          .from('read_devotionals')
          .select('read_at')
          .eq('user_profile_id', user.id)
          .gte('read_at', '$today 00:00:00')
          .lte('read_at', '$today 23:59:59')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar se algum devocional foi lido hoje: $e');
      return false;
    }
  }

  // Atualizar streak de leitura
  static Future<void> _updateStreak() async {
    try {
      final userStats = await getUserStats();
      if (userStats == null) return;

      final today = DateTime.now();
      final lastActivity = userStats.lastActivityDate;

      int newStreak = userStats.currentStreakDays;
      int totalDevotionalsRead = userStats.totalDevotionalsRead;

      if (lastActivity == null) {
        // Primeira atividade do usuário
        newStreak = 1;
        totalDevotionalsRead += 1;
      } else {
        final difference = today.difference(lastActivity).inDays;

        if (difference == 1) {
          // Dia consecutivo
          newStreak++;
          totalDevotionalsRead += 1;
        } else if (difference > 1) {
          // Quebrou o streak
          newStreak = 1;
          totalDevotionalsRead += 1;
        } else if (difference == 0) {
          // Mesmo dia - verificar se é primeira leitura do dia
          final todayStr = today.toIso8601String().split('T')[0];
          final hasReadToday = await _hasReadAnyDevotionalToday(todayStr);

          if (!hasReadToday) {
            // Primeira leitura do dia
            totalDevotionalsRead += 1;
          }
          // Se já leu hoje, não incrementar nada
        }
      }

      // Verificar bônus de streak (só se streak aumentou)
      if (newStreak > userStats.currentStreakDays) {
        if (newStreak == 3) {
          await addXp(
            actionName: 'streak_bonus',
            xpAmount: 15,
            description: 'Bônus por 3 dias seguidos',
          );
        } else if (newStreak == 7) {
          await addXp(
            actionName: 'streak_bonus',
            xpAmount: 35,
            description: 'Bônus por 7 dias seguidos',
          );
        } else if (newStreak == 30) {
          await addXp(
            actionName: 'streak_bonus',
            xpAmount: 150,
            description: 'Bônus por 30 dias seguidos',
          );
        }
      }

      // Atualizar estatísticas
      final updatedStats = userStats.copyWith(
        currentStreakDays: newStreak,
        longestStreakDays: newStreak > userStats.longestStreakDays
            ? newStreak
            : userStats.longestStreakDays,
        lastActivityDate: today,
        totalDevotionalsRead: totalDevotionalsRead,
      );

      _localCache['user_stats'] = updatedStats.toJson();
      await _saveCache();

      print(
        'Streak atualizado: $newStreak dias, Total lidos: $totalDevotionalsRead',
      );
    } catch (e) {
      print('Erro ao atualizar streak: $e');
    }
  }

  // Verificar conquistas
  static Future<void> _checkAchievements() async {
    try {
      final userStats = await getUserStats();
      if (userStats == null) return;

      final achievements = await getAllAchievements();
      final unlockedAchievements = await getUserAchievements();

      for (final achievement in achievements) {
        // Pular se já foi desbloqueada
        if (unlockedAchievements.any((ua) => ua.id == achievement.id)) {
          continue;
        }

        bool shouldUnlock = false;

        switch (achievement.requirementType) {
          case 'devotionals_read':
            shouldUnlock =
                userStats.totalDevotionalsRead >= achievement.requirementValue;
            break;
          case 'streak_days':
            shouldUnlock =
                userStats.currentStreakDays >= achievement.requirementValue;
            break;
          case 'highlights':
            shouldUnlock =
                userStats.totalHighlights >= achievement.requirementValue;
            break;
          case 'chapters_read':
            shouldUnlock =
                userStats.chaptersReadCount >= achievement.requirementValue;
            break;
        }

        if (shouldUnlock) {
          await _unlockAchievement(achievement);
        }
      }
    } catch (e) {
      print('Erro ao verificar conquistas: $e');
    }
  }

  // Desbloquear conquista
  static Future<void> _unlockAchievement(Achievement achievement) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Já existe no servidor?
      final existing = await Supabase.instance.client
          .from('user_achievements')
          .select('id')
          .eq('user_id', user.id)
          .eq('achievement_id', achievement.id)
          .maybeSingle();
      if (existing != null) return; // já desbloqueada

      // Registrar conquista no Supabase (evita duplicado)
      await Supabase.instance.client.from('user_achievements').upsert({
        'user_id': user.id,
        'achievement_id': achievement.id,
        'unlocked_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,achievement_id');

      // Adicionar XP da conquista (apenas na primeira vez)
      await addXp(
        actionName: 'achievement_unlocked',
        xpAmount: achievement.xpReward,
        description: 'Conquista: ${achievement.title}',
        relatedId: achievement.id,
      );

      // Atualizar cache local
      final unlockedAchievements = _localCache['achievements'] ?? [];
      final achievementWithUnlock = achievement.copyWith(
        unlockedAt: DateTime.now(),
      );
      unlockedAchievements.add(achievementWithUnlock.toJson());
      _localCache['achievements'] = unlockedAchievements;

      await _saveCache();

      _emitEvent('achievement_unlocked');
      print('🏆 Conquista desbloqueada: ${achievement.title}');
    } catch (e) {
      print('Erro ao desbloquear conquista: $e');
    }
  }

  // Obter XP total do usuário
  static Future<int> getTotalXp() async {
    await _syncIfNeeded();
    return _localCache['total_xp'] ?? 0;
  }

  // Obter nível atual
  static Future<int> getCurrentLevel() async {
    final totalXp = await getTotalXp();
    return _levelForXp(totalXp);
  }

  // Obter XP necessário para o próximo nível
  static Future<int> getXpToNextLevel() async {
    final totalXp = await getTotalXp();
    final currentLevel = await getCurrentLevel();

    final levelRequirements = [0, 150, 400, 750, 1200];

    if (currentLevel >= 5) return 0;

    return levelRequirements[currentLevel] - totalXp;
  }

  static int _levelForXp(int totalXp) {
    final levelRequirements = [0, 150, 400, 750, 1200];
    int level = 1;
    for (int i = 1; i < levelRequirements.length; i++) {
      if (totalXp >= levelRequirements[i]) {
        level = i + 1; // níveis começam em 1
      }
    }
    // Se atingir o último limite, permanece no último nível configurado
    return level.clamp(1, levelRequirements.length);
  }

  // Obter informações do nível atual
  static Future<Level?> getCurrentLevelInfo() async {
    try {
      final currentLevel = await getCurrentLevel();

      final response = await Supabase.instance.client
          .from('levels')
          .select()
          .eq('level_number', currentLevel)
          .single();

      return Level.fromJson(response);
    } catch (e) {
      print('Erro ao obter informações do nível: $e');
      return null;
    }
  }

  // Obter estatísticas do usuário
  static Future<UserStats?> getUserStats() async {
    await _syncIfNeeded();

    final statsData = _localCache['user_stats'];
    if (statsData == null) return null;

    return UserStats.fromJson(statsData);
  }

  // Obter todas as conquistas
  static Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await Supabase.instance.client
          .from('achievements')
          .select()
          .eq('is_active', true)
          .order('requirement_value');

      return response.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao obter conquistas: $e');
      return [];
    }
  }

  // Obter conquistas do usuário
  static Future<List<Achievement>> getUserAchievements() async {
    await _syncIfNeeded();

    final dynamic achievementsData = _localCache['achievements'] ?? [];
    final List<dynamic> list = achievementsData is List
        ? achievementsData
        : <dynamic>[];

    final List<Achievement> parsed = [];
    for (final item in list) {
      try {
        if (item is Achievement) {
          parsed.add(item);
        } else if (item is Map) {
          parsed.add(Achievement.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (_) {
        // ignora entradas inválidas
      }
    }

    return parsed.where((a) => a.isUnlocked).toList();
  }

  // Métodos auxiliares para Supabase
  static Future<UserStats?> _getUserStatsFromSupabase(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? UserStats.fromJson(response) : null;
    } catch (e) {
      print('Erro ao obter estatísticas do Supabase: $e');
      return null;
    }
  }

  static Future<List<Achievement>> _getUserAchievementsFromSupabase(
    String userId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('user_achievements')
          .select('''
            achievement_id,
            unlocked_at,
            achievements (*)
          ''')
          .eq('user_id', userId);

      return response.map((json) {
        final achievementData = json['achievements'] as Map<String, dynamic>;
        achievementData['unlocked_at'] = json['unlocked_at'];
        return Achievement.fromJson(achievementData);
      }).toList();
    } catch (e) {
      print('Erro ao obter conquistas do Supabase: $e');
      return [];
    }
  }

  static Future<int> _getUserTotalXpFromSupabase(String userId) async {
    try {
      // Tenta RPC padrão
      final response = await Supabase.instance.client.rpc(
        'get_user_total_xp',
        params: {'user_uuid': userId},
      );
      if (response != null) return response as int;
    } catch (e) {
      print('RPC get_user_total_xp indisponível, somando diretamente: $e');
    }

    // Soma direta no esquema atual (xp_amount/user_id)
    try {
      final res = await Supabase.instance.client
          .from('xp_transactions')
          .select('xp_amount')
          .eq('user_id', userId);
      int sum = 0;
      for (final row in res) {
        final v = row['xp_amount'];
        if (v is int) {
          sum += v;
        } else if (v is num)
          sum += v.toInt();
      }
      return sum;
    } catch (e) {
      print('Falha ao somar xp_amount: $e');
      return 0;
    }
  }

  // Forçar sincronização
  static Future<void> forceSync() async {
    await _syncWithSupabase();
  }

  // Limpar cache local
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastSyncKey);

      // Limpar cache em memória
      _localCache = {};
      _lastSync = null;

      print('Cache de gamificação limpo com sucesso');
    } catch (e) {
      print('Erro ao limpar cache de gamificação: $e');
    }
  }
}
