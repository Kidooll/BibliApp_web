import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/achievement.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/app_constants.dart';

class AchievementService {
  static const String _achievementsKey = 'user_achievements';
  static const String _context = 'AchievementService';
  static const Duration _memoryCacheTtl = Duration(minutes: 5);
  static List<Achievement>? _memoryCache;
  static DateTime? _memoryCacheAt;
  static String? _memoryCacheUserId;

  static String? _getCurrentUserId() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  static String _buildAchievementsKey(String? userId) {
    if (userId == null || userId.isEmpty) {
      return _achievementsKey;
    }
    return '${_achievementsKey}_$userId';
  }

  static bool _isMemoryCacheValid(String? userId) {
    if (_memoryCache == null || _memoryCacheAt == null) {
      return false;
    }
    if (_memoryCacheUserId != userId) {
      return false;
    }
    return DateTime.now().difference(_memoryCacheAt!) < _memoryCacheTtl;
  }

  static void _updateMemoryCache(
    String? userId,
    List<Achievement> achievements,
  ) {
    _memoryCacheUserId = userId;
    _memoryCacheAt = DateTime.now();
    _memoryCache = List<Achievement>.from(achievements);
  }

  static void _clearMemoryCache() {
    _memoryCache = null;
    _memoryCacheAt = null;
    _memoryCacheUserId = null;
  }

  static AchievementType _mapRequirementType(String? requirementType) {
    switch (requirementType) {
      case 'streak_days':
        return AchievementType.streak;
      case 'devotionals_read':
        return AchievementType.devotionalCount;
      case 'total_xp':
        return AchievementType.totalXp;
      case 'highlights':
        return AchievementType.highlights;
      case 'chapters_read':
        return AchievementType.chaptersRead;
      default:
        return AchievementType.special;
    }
  }

  static String _mapIconName(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return '🏆';
    }
    if (iconName.runes.length <= 2) {
      return iconName;
    }
    const iconMap = {
      'first_light': '✨',
      'constancy_strength': '🔥',
      'sacred_mark': '🖍️',
      'word_explorer': '🧭',
      'faithful_month': '👑',
    };
    return iconMap[iconName] ?? '🏆';
  }

  static DateTime? _parseUnlockedAt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static Future<List<Achievement>> _fetchAchievementsFromSupabase(
    String userId,
  ) async {
    final client = Supabase.instance.client;
    final achievementsResponse = await client
        .from('achievements')
        .select(
          'id, title, description, icon_name, xp_reward, requirement_type, requirement_value, is_active',
        )
        .eq('is_active', true)
        .order('id', ascending: true);

    final unlockedResponse = await client
        .from('user_achievements')
        .select('achievement_id, unlocked_at')
        .eq('user_id', userId);

    final unlockedById = <String, DateTime>{};
    for (final row in List<Map<String, dynamic>>.from(unlockedResponse)) {
      final id = row['achievement_id']?.toString();
      if (id == null) continue;
      final unlockedAt = _parseUnlockedAt(row['unlocked_at']);
      if (unlockedAt != null) {
        unlockedById[id] = unlockedAt;
      }
    }

    return List<Map<String, dynamic>>.from(achievementsResponse)
        .map((row) {
          final id = row['id']?.toString() ?? '';
          final unlockedAt = unlockedById[id];
          return Achievement(
            id: id,
            title: row['title'] as String? ?? '',
            description: row['description'] as String? ?? '',
            icon: _mapIconName(row['icon_name'] as String?),
            xpReward: (row['xp_reward'] as num?)?.toInt() ?? 0,
            type: _mapRequirementType(row['requirement_type'] as String?),
            targetValue: (row['requirement_value'] as num?)?.toInt() ?? 1,
            isUnlocked: unlockedAt != null,
            unlockedAt: unlockedAt,
          );
        })
        .toList();
  }

  static final List<Achievement> _defaultAchievements = [
    // Streak Achievements
    const Achievement(
      id: 'streak_3',
      title: 'Constância',
      description: 'Complete 3 dias consecutivos',
      icon: '🔥',
      xpReward: XpValues.streak3Days,
      type: AchievementType.streak,
      targetValue: 3,
    ),
    const Achievement(
      id: 'streak_7',
      title: 'Dedicação',
      description: 'Complete 7 dias consecutivos',
      icon: '⭐',
      xpReward: XpValues.streak7Days,
      type: AchievementType.streak,
      targetValue: 7,
    ),
    const Achievement(
      id: 'streak_30',
      title: 'Mestre da Disciplina',
      description: 'Complete 30 dias consecutivos',
      icon: '👑',
      xpReward: 100,
      type: AchievementType.streak,
      targetValue: 30,
    ),
    
    // XP Achievements
    const Achievement(
      id: 'xp_100',
      title: 'Primeiro Passo',
      description: 'Alcance 100 XP total',
      icon: '🌱',
      xpReward: 20,
      type: AchievementType.totalXp,
      targetValue: 100,
    ),
    const Achievement(
      id: 'xp_500',
      title: 'Crescimento',
      description: 'Alcance 500 XP total',
      icon: '🌿',
      xpReward: 50,
      type: AchievementType.totalXp,
      targetValue: 500,
    ),
    const Achievement(
      id: 'xp_1000',
      title: 'Sabedoria',
      description: 'Alcance 1000 XP total',
      icon: '🌳',
      xpReward: 100,
      type: AchievementType.totalXp,
      targetValue: 1000,
    ),
    
    // First Time Achievements
    const Achievement(
      id: 'first_devotional',
      title: 'Primeira Leitura',
      description: 'Complete seu primeiro devocional',
      icon: '📖',
      xpReward: 10,
      type: AchievementType.firstTime,
      targetValue: 1,
    ),
    const Achievement(
      id: 'first_audio',
      title: 'Primeira Escuta',
      description: 'Ouça seu primeiro áudio',
      icon: '🎧',
      xpReward: 10,
      type: AchievementType.firstTime,
      targetValue: 1,
    ),
    
    // Devotional Count Achievements
    const Achievement(
      id: 'devotional_10',
      title: 'Leitor Iniciante',
      description: 'Complete 10 devocionais',
      icon: '📚',
      xpReward: 30,
      type: AchievementType.devotionalCount,
      targetValue: 10,
    ),
    const Achievement(
      id: 'devotional_50',
      title: 'Leitor Dedicado',
      description: 'Complete 50 devocionais',
      icon: '📜',
      xpReward: 75,
      type: AchievementType.devotionalCount,
      targetValue: 50,
    ),
  ];

  static Future<List<Achievement>> getAchievements() async {
    try {
      final userId = _getCurrentUserId();
      if (_isMemoryCacheValid(userId)) {
        return List<Achievement>.from(_memoryCache!);
      }

      final prefs = await SharedPreferences.getInstance();
      final key = _buildAchievementsKey(userId);

      if (userId != null) {
        final legacyJson = prefs.getString(_achievementsKey);
        if (legacyJson != null && !prefs.containsKey(key)) {
          await prefs.setString(key, legacyJson);
          await prefs.remove(_achievementsKey);
        }
      }

      if (userId != null) {
        try {
          final remoteAchievements = await _fetchAchievementsFromSupabase(userId);
          await _saveAchievements(remoteAchievements);
          _updateMemoryCache(userId, remoteAchievements);
          return remoteAchievements;
        } catch (e, stack) {
          LogService.error(
            'Erro ao carregar conquistas do Supabase',
            e,
            stack,
            _context,
          );
        }
      }

      final achievementsJson = prefs.getString(key);
      if (achievementsJson == null) {
        if (userId != null) {
          await _initializeAchievements(key);
        }
        _updateMemoryCache(userId, _defaultAchievements);
        return _defaultAchievements;
      }

      final List<dynamic> achievementsList = json.decode(achievementsJson);
      final achievements =
          achievementsList.map((json) => Achievement.fromJson(json)).toList();
      _updateMemoryCache(userId, achievements);
      return achievements;
    } catch (e, stack) {
      LogService.error('Erro ao carregar conquistas', e, stack, _context);
      return _defaultAchievements;
    }
  }

  static Future<void> _initializeAchievements(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = json.encode(
        _defaultAchievements.map((a) => a.toJson()).toList(),
      );
      await prefs.setString(key, achievementsJson);
    } catch (e, stack) {
      LogService.error('Erro ao inicializar conquistas', e, stack, _context);
    }
  }

  static Future<List<Achievement>> checkAndUnlockAchievements({
    required int currentStreak,
    required int totalXp,
    required int devotionalCount,
    required bool hasReadDevotional,
    required bool hasListenedAudio,
    int totalHighlights = 0,
    int chaptersReadCount = 0,
  }) async {
    try {
      final achievements = await getAchievements();
      final newlyUnlocked = <Achievement>[];
      
      for (int i = 0; i < achievements.length; i++) {
        final achievement = achievements[i];
        if (achievement.isUnlocked) continue;
        
        bool shouldUnlock = false;
        
        switch (achievement.type) {
          case AchievementType.streak:
            shouldUnlock = currentStreak >= achievement.targetValue;
            break;
          case AchievementType.totalXp:
            shouldUnlock = totalXp >= achievement.targetValue;
            break;
          case AchievementType.devotionalCount:
            shouldUnlock = devotionalCount >= achievement.targetValue;
            break;
          case AchievementType.firstTime:
            if (achievement.id == 'first_devotional') {
              shouldUnlock = hasReadDevotional;
            } else if (achievement.id == 'first_audio') {
              shouldUnlock = hasListenedAudio;
            }
            break;
          case AchievementType.highlights:
            shouldUnlock = totalHighlights >= achievement.targetValue;
            break;
          case AchievementType.chaptersRead:
            shouldUnlock = chaptersReadCount >= achievement.targetValue;
            break;
          case AchievementType.special:
            // Implementar lógica especial se necessário
            break;
        }
        
        if (shouldUnlock) {
          final unlockedAchievement = achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          achievements[i] = unlockedAchievement;
          newlyUnlocked.add(unlockedAchievement);
        }
      }
      
      if (newlyUnlocked.isNotEmpty) {
        await _persistUnlockedAchievements(newlyUnlocked);
        await _saveAchievements(achievements);
        LogService.info('${newlyUnlocked.length} conquistas desbloqueadas', _context);
      }
      
      return newlyUnlocked;
    } catch (e, stack) {
      LogService.error('Erro ao verificar conquistas', e, stack, _context);
      return [];
    }
  }

  static Future<void> _saveAchievements(List<Achievement> achievements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildAchievementsKey(_getCurrentUserId());
      final achievementsJson = json.encode(
        achievements.map((a) => a.toJson()).toList(),
      );
      await prefs.setString(key, achievementsJson);
      _updateMemoryCache(_getCurrentUserId(), achievements);
    } catch (e, stack) {
      LogService.error('Erro ao salvar conquistas', e, stack, _context);
    }
  }

  static Future<void> _persistUnlockedAchievements(
    List<Achievement> achievements,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || achievements.isEmpty) {
      return;
    }

    try {
      final payload = <Map<String, dynamic>>[];
      for (final achievement in achievements) {
        final parsedId = int.tryParse(achievement.id);
        if (parsedId == null) {
          continue;
        }
        payload.add({
          'user_id': user.id,
          'achievement_id': parsedId,
          'unlocked_at':
              (achievement.unlockedAt ?? DateTime.now()).toIso8601String(),
        });
      }
      if (payload.isEmpty) {
        return;
      }
      await Supabase.instance.client
          .from('user_achievements')
          .upsert(payload, onConflict: 'user_id,achievement_id');
    } catch (e, stack) {
      LogService.error('Erro ao salvar conquistas no Supabase', e, stack, _context);
    }
  }

  static Future<int> getUnlockedCount() async {
    final achievements = await getAchievements();
    return achievements.where((a) => a.isUnlocked).length;
  }

  static Future<int> getTotalXpFromAchievements() async {
    final achievements = await getAchievements();
    return achievements
        .where((a) => a.isUnlocked)
        .fold<int>(0, (sum, a) => sum + a.xpReward);
  }

  static Future<void> clearCache({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveUserId = userId ?? _getCurrentUserId();
      await prefs.remove(_achievementsKey);
      if (effectiveUserId != null) {
        await prefs.remove(_buildAchievementsKey(effectiveUserId));
      }
      _clearMemoryCache();
    } catch (e, stack) {
      LogService.error('Erro ao limpar cache de conquistas', e, stack, _context);
    }
  }
}
