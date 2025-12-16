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
  static const String _streakRepairKey = 'streak_repair_last_day';

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
  // OBS: esta função deve ser chamada após o INSERT em read_devotionals ter ocorrido com sucesso.
  static Future<void> markDevotionalAsRead(
    int devotionalId, {
    required bool firstReadOfDay,
  }) async {
    try {
      await _syncIfNeeded();

      // Adicionar XP por ler devocional
      await addXp(
        actionName: 'devotional_read',
        xpAmount: 8,
        description: 'Devocional lido',
        relatedId: devotionalId,
      );

      // Verificar se é primeira leitura do dia (qualquer devocional)
      if (firstReadOfDay) {
        await addXp(
          actionName: 'daily_bonus',
          xpAmount: 5,
          description: 'Primeira leitura do dia',
        );
      }

      // Atualizar streak/estatísticas
      await _updateStreak(firstReadOfDay: firstReadOfDay);
      _emitEvent('streak_changed');

      await _saveCache();
    } catch (e) {
      print('Erro ao marcar devocional como lido: $e');
    }
  }

  /// Recalcula a streak a partir do histórico (read_devotionals) e corrige
  /// `user_stats/reading_streaks` caso estejam divergentes.
  ///
  /// Útil para "curar" streaks travadas por problemas antigos ou triggers.
  static Future<void> repairStreakFromHistoryIfNeeded() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Evitar fazer reparo repetidamente no mesmo dia (custo de query).
      final todayUtc = DateTime.now().toUtc();
      final todayKey = _dateKeyUtc(todayUtc);
      if (_localCache[_streakRepairKey] == todayKey) return;

      await _syncIfNeeded();
      final existing = await getUserStats();

      final days = await _fetchReadDaysUtc(limit: 120);
      if (days.isEmpty) {
        _localCache[_streakRepairKey] = todayKey;
        await _saveCache();
        return;
      }

      final computed = _calculateCurrentStreakFromDayKeys(days, todayUtc);
      final lastReadKey = _maxDayKey(days);

      final current = existing?.currentStreakDays ?? 0;
      if (computed == current) {
        _localCache[_streakRepairKey] = todayKey;
        await _saveCache();
        return;
      }

      final longest = existing == null
          ? computed
          : (computed > existing.longestStreakDays
              ? computed
              : existing.longestStreakDays);

      // Persistir correção no servidor
      await Supabase.instance.client.from('user_stats').upsert({
        'user_id': user.id,
        'current_streak_days': computed,
        'longest_streak_days': longest,
        'last_activity_date': lastReadKey,
        'last_sync_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      await Supabase.instance.client.from('reading_streaks').upsert({
        'user_profile_id': user.id,
        'current_streak_days': computed,
        'longest_streak_days': longest,
        'last_active_date': lastReadKey,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_profile_id');

      // Atualizar cache (evita inconsistência por campos obrigatórios como `id/created_at`)
      await forceSync();
      _localCache[_streakRepairKey] = todayKey;
      await _saveCache();
      _emitEvent('streak_changed');
    } catch (e) {
      print('Erro ao reparar streak: $e');
    }
  }

  // Atualizar streak de leitura
  static Future<void> _updateStreak({required bool firstReadOfDay}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      UserStats? userStats = await getUserStats();
      if (userStats == null) {
        // Garantir linha em user_stats para não falhar em novas leituras
        await Supabase.instance.client.from('user_stats').upsert({
          'user_id': user.id,
          'total_devotionals_read': 0,
          'current_streak_days': 0,
          'longest_streak_days': 0,
          'last_activity_date': null,
          'last_sync_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
        await forceSync();
        userStats = await getUserStats();
        if (userStats == null) return;
      }

      final nowUtc = DateTime.now().toUtc();
      final today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

      int newStreak = userStats.currentStreakDays;
      final totalDevotionalsRead = userStats.totalDevotionalsRead + 1;

      // Streak só muda na primeira leitura do dia; mas recalculamos pelo histórico para corrigir valores "travados".
      if (firstReadOfDay) {
        newStreak = await _calculateCurrentStreakFromHistory(
          today,
          includeTodayIfMissing: true,
        );
      } else if (userStats.lastActivityDate == null) {
        newStreak = 1;
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

      final todayStr = today.toIso8601String().split('T')[0];

      // Persistir no Supabase para refletir na Home/Missões
      await Supabase.instance.client.from('user_stats').upsert({
        'user_id': user.id,
        'total_devotionals_read': totalDevotionalsRead,
        'current_streak_days': newStreak,
        'longest_streak_days': newStreak > userStats.longestStreakDays
            ? newStreak
            : userStats.longestStreakDays,
        'last_activity_date': todayStr,
        'last_sync_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Atualizar leitura semanal/contagem simples na user_profiles
      await Supabase.instance.client.from('user_profiles').upsert({
        'id': user.id,
        'total_devotionals_read': totalDevotionalsRead,
        'current_level': await getCurrentLevel(),
        'total_xp': await getTotalXp(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      // Persistir streak na tabela reading_streaks (para consumo da Home)
      await Supabase.instance.client.from('reading_streaks').upsert({
        'user_profile_id': user.id,
        'current_streak_days': newStreak,
        'longest_streak_days': newStreak > userStats.longestStreakDays
            ? newStreak
            : userStats.longestStreakDays,
        'last_active_date': todayStr,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_profile_id');

      print(
        'Streak atualizado: $newStreak dias, Total lidos: $totalDevotionalsRead',
      );
    } catch (e) {
      print('Erro ao atualizar streak: $e');
    }
  }

  static String _dateKeyUtc(DateTime utcDate) {
    final d = DateTime.utc(utcDate.year, utcDate.month, utcDate.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDateOnlyUtc(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return DateTime.utc(raw.year, raw.month, raw.day);
    }
    if (raw is String) {
      // Prefer date-only: YYYY-MM-DD
      final parts = raw.split('-');
      if (parts.length == 3 && parts[0].length == 4) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2].split('T').first);
        if (y != null && m != null && d != null) {
          return DateTime.utc(y, m, d);
        }
      }
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final utc = dt.toUtc();
        return DateTime.utc(utc.year, utc.month, utc.day);
      }
    }
    return null;
  }

  static Future<Set<String>> _fetchReadDaysUtc({int limit = 60}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return <String>{};
    try {
      final res = await Supabase.instance.client
          .from('read_devotionals')
          .select('read_date,read_at')
          .eq('user_profile_id', user.id)
          .order('read_at', ascending: false)
          .limit(limit);
      final days = <String>{};
      for (final row in res) {
        final dt = _parseDateOnlyUtc(row['read_date']) ??
            _parseDateOnlyUtc(row['read_at']);
        if (dt == null) continue;
        days.add(_dateKeyUtc(dt));
      }
      return days;
    } catch (_) {
      return <String>{};
    }
  }

  static String _maxDayKey(Set<String> keys) {
    String? maxKey;
    for (final k in keys) {
      if (maxKey == null || k.compareTo(maxKey) > 0) {
        maxKey = k;
      }
    }
    return maxKey ?? _dateKeyUtc(DateTime.now().toUtc());
  }

  static int _calculateCurrentStreakFromDayKeys(
    Set<String> dayKeys,
    DateTime todayUtc,
  ) {
    if (dayKeys.isEmpty) return 0;

    final today = DateTime.utc(todayUtc.year, todayUtc.month, todayUtc.day);
    final lastKey = _maxDayKey(dayKeys);
    final lastDate = _parseDateOnlyUtc(lastKey);
    if (lastDate == null) return 0;

    final diffDays = today.difference(lastDate).inDays;
    if (diffDays >= 2) return 0; // streak quebrada

    int streak = 0;
    DateTime cursor = lastDate;
    while (true) {
      final k = _dateKeyUtc(cursor);
      if (!dayKeys.contains(k)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak.clamp(0, 3650);
  }

  static Future<int> _calculateCurrentStreakFromHistory(
    DateTime todayUtcDate, {
    required bool includeTodayIfMissing,
  }) async {
    try {
      final todayKey = _dateKeyUtc(todayUtcDate);
      final days = await _fetchReadDaysUtc(limit: 120);
      if (includeTodayIfMissing) {
        days.add(todayKey);
      }
      final computed = _calculateCurrentStreakFromDayKeys(days, todayUtcDate);
      return includeTodayIfMissing ? computed.clamp(1, 3650) : computed;
    } catch (_) {
      return includeTodayIfMissing ? 1 : 0;
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

  /// Retorna as últimas transações de XP para exibir histórico (limite padrão: 3)
  static Future<List<Map<String, dynamic>>> getRecentXpTransactions({
    int limit = 3,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final res = await Supabase.instance.client
          .from('xp_transactions')
          .select('xp_amount, transaction_type, description, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Erro ao buscar histórico de XP: $e');
      return [];
    }
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
