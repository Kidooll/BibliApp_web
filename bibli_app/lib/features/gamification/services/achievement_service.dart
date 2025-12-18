import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/achievement.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/app_constants.dart';

class AchievementService {
  static const String _achievementsKey = 'user_achievements';
  static const String _context = 'AchievementService';

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
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      
      if (achievementsJson == null) {
        await _initializeAchievements();
        return _defaultAchievements;
      }
      
      final List<dynamic> achievementsList = json.decode(achievementsJson);
      return achievementsList.map((json) => Achievement.fromJson(json)).toList();
    } catch (e, stack) {
      LogService.error('Erro ao carregar conquistas', e, stack, _context);
      return _defaultAchievements;
    }
  }

  static Future<void> _initializeAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = json.encode(
        _defaultAchievements.map((a) => a.toJson()).toList(),
      );
      await prefs.setString(_achievementsKey, achievementsJson);
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
      final achievementsJson = json.encode(
        achievements.map((a) => a.toJson()).toList(),
      );
      await prefs.setString(_achievementsKey, achievementsJson);
    } catch (e, stack) {
      LogService.error('Erro ao salvar conquistas', e, stack, _context);
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
}