import 'dart:async';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/home/services/home_service.dart';
import '../../../features/gamification/models/achievement.dart';
import '../../../features/gamification/models/level.dart';
import '../../../features/gamification/models/user_stats.dart';
import '../../../features/gamification/services/gamification_service.dart';
import '../../../features/quotes/screens/quote_screen.dart';
import '../services/missions_service.dart';
import '../services/weekly_challenges_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/core/services/log_service.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _xpAnimationController;
  late AnimationController _levelUpController;
  late Animation<double> _xpAnimation;
  late Animation<double> _levelUpAnimation;
  StreamSubscription<String>? _gamificationSub;
  bool _isRefreshing = false;
  bool _isDisposed = false;
  int _selectedTabIndex = 0; // 0: Diárias, 1: Semanais, 2: Conquistas

  Level? _currentLevel;
  int _totalXp = 0;
  int _xpToNextLevel = 0;
  List<Achievement> _achievements = [];
  List<Achievement> _unlockedAchievements = [];
  UserStats? _userStats;
  bool _isLoading = true;
  List<Level> _levels = [];
  int _coins = 0;
  String? _username;
  Map<String, String?> _todaysQuote = {};
  List<Map<String, dynamic>> _todayMissions = [];
  List<Map<String, dynamic>> _recentXp = [];
  late MissionsService _missionsService;
  late WeeklyChallengesService _weeklyService;
  List<Map<String, dynamic>> _weeklyProgress = [];
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _recent = [];

  @override
  void initState() {
    super.initState();
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _xpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeInOut),
    );

    _levelUpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );

    _loadData();

    // Feedback de conquistas
    _gamificationSub = GamificationService.events.listen((event) {
      if (!mounted || _isDisposed) return;
      if (event == 'achievement_unlocked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Conquista desbloqueada!'),
            duration: Duration(seconds: 2),
          ),
        );
        _levelUpController.forward(from: 0);
      }
      if (event == 'xp_changed' ||
          event == 'level_up' ||
          event == 'streak_changed') {
        _refreshGamificationData();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _xpAnimationController.dispose();
    _levelUpController.dispose();
    _gamificationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Inicializar gamificação
      await GamificationService.initialize();
      await GamificationService.forceSync();
      await GamificationService.repairStreakFromHistoryIfNeeded();

      _missionsService = MissionsService(Supabase.instance.client);
      _weeklyService = WeeklyChallengesService(Supabase.instance.client);
      await _missionsService.prepareTodayMissions();
      final todayMissions = await _missionsService.getTodayMissions();
      final weekly = await _weeklyService.getWeeklyChallengesWithProgress();
      final upcoming = await _weeklyService.getUpcomingChallenges();
      final recent = await _weeklyService.getRecentChallenges();
      final todaysQuote = await HomeService(
        Supabase.instance.client,
      ).getTodaysQuote();

      // Carregar dados
      final totalXp = await GamificationService.getTotalXp();
      final currentLevel = await GamificationService.getCurrentLevelInfo();
      final xpToNextLevel = await GamificationService.getXpToNextLevel();
      final achievements = await GamificationService.getAllAchievements();
      final unlockedAchievements =
          await GamificationService.getUserAchievements();
      final userStats = await GamificationService.getUserStats();
      final levels = await _fetchLevels();
      final coins = await _fetchCoins();
      final recentXp = await GamificationService.getRecentXpTransactions();
      final username = await _fetchUsername();

      if (mounted && !_isDisposed) {
        setState(() {
          _totalXp = totalXp;
          _currentLevel = currentLevel;
          _xpToNextLevel = xpToNextLevel;
          _achievements = achievements;
          _unlockedAchievements = unlockedAchievements;
          _userStats = userStats;
          _levels = levels;
          _coins = coins;
          _recentXp = recentXp;
          _username = username;
          _todaysQuote = todaysQuote;
          _todayMissions = todayMissions;
          _weeklyProgress = weekly;
          _upcoming = upcoming;
          _recent = recent;
          _isLoading = false;
        });
      }

      // Iniciar animação da barra de XP
      _xpAnimationController.forward();
    } catch (e, stack) {
      LogService.error('Erro ao carregar dados', e, stack, 'MissionsScreen');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Level>> _fetchLevels() async {
    try {
      final res = await Supabase.instance.client
          .from('levels')
          .select()
          .order('level_number');
      return List<Map<String, dynamic>>.from(
        res,
      ).map((e) => Level.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> _fetchCoins() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0;
      final res = await Supabase.instance.client
          .from('user_profiles')
          .select('coins')
          .eq('id', user.id)
          .maybeSingle();
      return (res?['coins'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _refreshGamificationData() async {
    if (_isRefreshing || _isDisposed) return;
    _isRefreshing = true;
    try {
      await GamificationService.forceSync();
      final totalXp = await GamificationService.getTotalXp();
      final currentLevel = await GamificationService.getCurrentLevelInfo();
      final xpToNextLevel = await GamificationService.getXpToNextLevel();
      final unlockedAchievements =
          await GamificationService.getUserAchievements();
      final userStats = await GamificationService.getUserStats();
      final recentXp = await GamificationService.getRecentXpTransactions();
      final coins = await _fetchCoins();
      final username = await _fetchUsername();

      if (mounted && !_isDisposed) {
        setState(() {
          _totalXp = totalXp;
          _currentLevel = currentLevel;
          _xpToNextLevel = xpToNextLevel;
          _unlockedAchievements = unlockedAchievements;
          _userStats = userStats;
          _recentXp = recentXp;
          _coins = coins;
          _username = username;
        });
        try {
          _xpAnimationController.forward(from: 0);
        } catch (_) {
          // Controller pode estar disposed
        }
      }
    } catch (e, stack) {
      LogService.error('Erro ao atualizar gamificação', e, stack, 'MissionsScreen');
    } finally {
      _isRefreshing = false;
    }
  }

  Future<String?> _fetchUsername() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      final res = await Supabase.instance.client
          .from('user_profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      return res?['username'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  // Header fixo
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 12),
                        _buildXpCard(),
                        const SizedBox(height: 16),
                        _buildTabBar(),
                      ],
                    ),
                  ),
                  // Conteúdo das tabs
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final currentLevel = _currentLevel?.levelNumber ?? 1;
    final levelName = _currentLevel?.levelName ?? 'Novato na Fé';
    final maxXp = _getMaxXpForLevel(currentLevel);
    final currentXpInLevel = _getCurrentXpInLevel(currentLevel);
    final progress = maxXp > 0 ? currentXpInLevel / maxXp : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005954), Color(0xFF007A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              badges.Badge(
                badgeContent: Text(
                  currentLevel.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.star, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Nível $currentLevel',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _xpAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'XP: ${(_totalXp * _xpAnimation.value).toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Próximo nível: $_xpToNextLevel XP',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    width: MediaQuery.of(context).size.width - 72,
                    lineHeight: 8,
                    percent: progress * _xpAnimation.value,
                    backgroundColor: Colors.white24,
                    progressColor: Colors.white,
                    barRadius: const Radius.circular(4),
                    animation: true,
                    animationDuration: 1500,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005954),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.book,
                  title: 'Devocionais',
                  value: '${_userStats?.totalDevotionalsRead ?? 0}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department,
                  title: 'Streak Atual',
                  value: '${_userStats?.currentStreakDays ?? 0} dias',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  title: 'Melhor Streak',
                  value: '${_userStats?.longestStreakDays ?? 0} dias',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.emoji_events,
                  title: 'Conquistas',
                  value: '${_unlockedAchievements.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF005954).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF005954), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005954),
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conquistas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005954),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _achievements.length,
          itemBuilder: (context, index) {
            final achievement = _achievements[index];
            final isUnlocked = _unlockedAchievements.any(
              (ua) => ua.id == achievement.id,
            );

            return _buildAchievementCard(achievement, isUnlocked);
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: isUnlocked
            ? Border.all(color: const Color(0xFF005954), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF005954).withOpacity(0.1)
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              size: 32,
              color: isUnlocked ? const Color(0xFF005954) : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              achievement.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? const Color(0xFF005954) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+${achievement.xpReward} XP',
            style: TextStyle(
              fontSize: 12,
              color: isUnlocked ? Colors.green : Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isUnlocked && achievement.unlockedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Desbloqueada em ${_formatDate(achievement.unlockedAt!)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _getMaxXpForLevel(int level) {
    const levelRequirements = LevelRequirements.requirements;
    if (level >= 5) return 0;
    return levelRequirements[level] - levelRequirements[level - 1];
  }

  int _getCurrentXpInLevel(int level) {
    const levelRequirements = LevelRequirements.requirements;
    if (level >= 5) return 0;
    final levelStartXp = levelRequirements[level - 1];
    return _totalXp - levelStartXp;
  }

  Widget _buildWeeklyChallengesSection() {
    if (_weeklyProgress.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: 'Nenhum desafio ativo',
        subtitle: 'Novos desafios semanais em breve!',
      );
    }

    return Column(
      children: _weeklyProgress.map((row) {
        final ch = row['weekly_challenges'] as Map<String, dynamic>? ?? {};
        final title = ch['title'] as String? ?? 'Desafio';
        final description = ch['description'] as String? ?? '';
        final target = ch['target_value'] as int? ?? 1;
        final progress = row['current_progress'] as int? ?? 0;
        final done = row['is_completed'] == true;
        final xp = ch['xp_reward'] as int? ?? 0;
        final type = ch['challenge_type'] as String? ?? 'reading';

        final pct = (target > 0) ? (progress / target).clamp(0, 1).toDouble() : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: done 
                ? [AppColors.primary.withOpacity(0.1), AppColors.complementary.withOpacity(0.1)]
                : [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: done ? Border.all(color: AppColors.primary, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Progress Ring
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          done ? Colors.green : AppColors.primary,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: done ? Colors.green : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getChallengeIcon(type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: done ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$progress/$target',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+$xp XP',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botão de ação
                if (done)
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await _weeklyService.claimChallenge(row['id'] as int);
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🏆 Recompensa: +$xp XP'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Resgatar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getChallengeIcon(String type) {
    switch (type) {
      case 'reading':
        return Icons.menu_book;
      case 'sharing':
        return Icons.share;
      case 'study':
        return Icons.auto_stories;
      case 'favorite':
        return Icons.favorite;
      case 'note':
        return Icons.edit_note;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.flag;
    }
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximos Desafios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005954),
          ),
        ),
        const SizedBox(height: 12),
        if (_upcoming.isEmpty)
          const Text('Nenhum desafio futuro cadastrado.')
        else
          Column(
            children: _upcoming.map((ch) {
              return ListTile(
                leading: const Icon(
                  Icons.event_available,
                  color: Color(0xFF005954),
                ),
                title: Text(ch['title'] ?? 'Desafio'),
                subtitle: Text(ch['description'] ?? ''),
                trailing: Text(
                  'Início: ${(ch['start_date'] ?? '').toString().substring(0, 10)}',
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWeeklyRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desafios Recentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005954),
          ),
        ),
        const SizedBox(height: 12),
        if (_recent.isEmpty)
          const Text('Nenhum desafio recente.')
        else
          Column(
            children: _recent.map((ch) {
              return ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF005954)),
                title: Text(ch['title'] ?? 'Desafio'),
                subtitle: Text(ch['description'] ?? ''),
                trailing: Text(
                  'Fim: ${(ch['end_date'] ?? '').toString().substring(0, 10)}',
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDailyMissionsSection() {
    if (_todayMissions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.flag,
        title: 'Nenhuma missão hoje',
        subtitle: 'Volte amanhã para novas missões!',
      );
    }

    return Column(
      children: _todayMissions.map((m) {
        final status = m['status'] as String? ?? 'pending';
        final mission = m['daily_missions'] as Map<String, dynamic>? ?? {};
        final title = mission['title'] as String? ?? 'Missão';
        final description = mission['description'] as String? ?? '';
        final xp = mission['xp_reward'] as int? ?? 0;
        final canClaim = status == 'completed';
        final claimed = status == 'claimed';
        final missionType = mission['mission_type'] as String? ?? 'general';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: claimed
                  ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                  : canClaim
                      ? [AppColors.primary.withOpacity(0.1), AppColors.complementary.withOpacity(0.1)]
                      : [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: claimed 
                ? Border.all(color: Colors.green, width: 2)
                : canClaim 
                    ? Border.all(color: AppColors.primary, width: 2)
                    : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Ícone da missão
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: claimed 
                        ? Colors.green
                        : canClaim 
                            ? AppColors.primary
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    claimed 
                        ? Icons.check_circle
                        : _getMissionIcon(missionType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: claimed ? Colors.green : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+$xp XP',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão de ação
                if (claimed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Concluída',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (canClaim)
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await _missionsService.claimMission(m['id'] as int);
                      if (!mounted) return;
                      if (ok) {
                        setState(() {
                          final idx = _todayMissions.indexWhere((it) => it['id'] == m['id']);
                          if (idx != -1) {
                            _todayMissions[idx]['status'] = 'claimed';
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎆 Recompensa: +$xp XP'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Resgatar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pendente',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getMissionIcon(String type) {
    switch (type) {
      case 'devotional':
        return Icons.menu_book;
      case 'share':
        return Icons.share;
      case 'streak':
        return Icons.local_fire_department;
      case 'reading':
        return Icons.auto_stories;
      default:
        return Icons.flag;
    }
  }

  Widget _buildHeaderCard() {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _username ?? user?.userMetadata?['name'] ?? 'Usuário';
    final initials = _getInitials(displayName);
    final levelNumber = _currentLevel?.levelNumber ?? 0;
    final achievementsCount = _unlockedAchievements.length;
    final streak = _userStats?.currentStreakDays ?? 0;
    final lastActivity = _userStats?.lastActivityDate;
    final statusLabel = _statusLabel(lastActivity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6B68), Color(0xFF0B5B53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF0B5B53),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatMini(label: 'Nível', value: '$levelNumber'),
              Container(width: 1, height: 24, color: Colors.white24),
              _buildStatMini(label: 'Talentos', value: '$_coins'),
              Container(width: 1, height: 24, color: Colors.white24),
              _buildStatMini(label: 'Conquistas', value: '$achievementsCount'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Streak atual: $streak dias',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildXpCard() {
    final levelName = _currentLevel?.levelName ?? 'Buscador';
    final currentLevelNumber = _currentLevel?.levelNumber ?? 1;
    final thresholds = _levelThresholds();

    // Garantir lista ordenada
    thresholds.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
    int idx = thresholds.indexWhere(
      (t) => (t['level'] ?? 0) == currentLevelNumber,
    );
    if (idx == -1) {
      idx = thresholds.indexWhere(
        (t) => (t['level'] ?? 0) > currentLevelNumber,
      );
    }
    if (idx == -1) idx = thresholds.length - 1;

    final prevThreshold = idx > 0 ? thresholds[idx - 1]['xp'] as int : 0;
    // Próximo limiar: usa entrada seguinte; se não houver, usa XP atual + xpToNextLevel
    int nextThreshold;
    if (idx + 1 < thresholds.length) {
      nextThreshold = thresholds[idx + 1]['xp'] as int;
    } else {
      final fallbackDelta = _xpToNextLevel > 0 ? _xpToNextLevel : LevelRequirements.defaultXpToNextLevel;
      nextThreshold = _totalXp + fallbackDelta;
    }

    final totalForLevel = (nextThreshold - prevThreshold).clamp(1, 1 << 31);
    final progress = ((_totalXp - prevThreshold) / totalForLevel)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F6A65),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'XP Total',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  levelName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_totalXp/$nextThreshold  XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFAEE0DB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneList() {
    final milestones = _levels.isNotEmpty ? _levels : _staticMilestones();
    final currentLevelNumber = _currentLevel?.levelNumber ?? 0;
    
    // Ordenar milestones em ordem crescente
    final sortedMilestones = List.from(milestones);
    sortedMilestones.sort((a, b) {
      final levelA = a is Level ? a.levelNumber : int.tryParse((a as Map<String, dynamic>)['level'] ?? '') ?? 0;
      final levelB = b is Level ? b.levelNumber : int.tryParse((b as Map<String, dynamic>)['level'] ?? '') ?? 0;
      return levelA.compareTo(levelB);
    });
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6EA9A8),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Caminhada da Fé',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...sortedMilestones.map(
            (dynamic m) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isLevelReached(
                            m is Level
                                ? m.levelNumber
                                : int.tryParse(
                                        (m as Map<String, dynamic>)['level'] ??
                                            '',
                                      ) ??
                                      0,
                            currentLevelNumber,
                          )
                          ? Icons.check_circle
                          : Icons.lock_open,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔥 Nível ${m is Level ? m.levelNumber : (m as Map<String, dynamic>)['level']} – ${m is Level ? m.levelName : (m as Map<String, dynamic>)['title']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m is Level
                              ? (m.description ?? '')
                              : ((m as Map<String, dynamic>)['description']
                                        as String? ??
                                    ''),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _staticMilestones() {
    return [
      {
        'level': '1',
        'title': 'Novato na Fé',
        'description': 'Iniciou a jornada espiritual (0-100 XP)',
      },
      {
        'level': '2',
        'title': 'Buscador',
        'description': 'Em busca de conhecimento (101-250 XP)',
      },
      {
        'level': '3',
        'title': 'Discípulo',
        'description': 'Comprometido com o aprendizado (251-500 XP)',
      },
      {
        'level': '4',
        'title': 'Servo Fiel',
        'description': 'Dedicado à prática diária (501-800 XP)',
      },
      {
        'level': '5',
        'title': 'Estudioso',
        'description': 'Conhecedor das Escrituras (801-1200 XP)',
      },
      {
        'level': '6',
        'title': 'Sábio',
        'description': 'Sabedoria espiritual (1201-1700 XP)',
      },
      {
        'level': '7',
        'title': 'Mestre',
        'description': 'Mestre na Palavra (1701-2300 XP)',
      },
      {
        'level': '8',
        'title': 'Líder Espiritual',
        'description': 'Líder e exemplo (2301-3000 XP)',
      },
      {
        'level': '9',
        'title': 'Mentor',
        'description': 'Guia de outros (3001-4000 XP)',
      },
      {
        'level': '10',
        'title': 'Gigante da Fé',
        'description': 'Máximo nível espiritual (4001+ XP)',
      },
    ];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    final initials = '$first$last';
    return initials.isNotEmpty ? initials : 'U';
  }

  List<Map<String, int>> _levelThresholds() {
    if (_levels.isNotEmpty) {
      return [
        {'level': 0, 'xp': 0},
        ..._levels.map((l) => {'level': l.levelNumber, 'xp': l.xpRequired}),
      ];
    }
    // Fallback usando valores do PRD
    return [
      {'level': 0, 'xp': 0},
      {'level': 1, 'xp': 101},
      {'level': 2, 'xp': 251},
      {'level': 3, 'xp': 501},
      {'level': 4, 'xp': 801},
      {'level': 5, 'xp': 1201},
      {'level': 6, 'xp': 1701},
      {'level': 7, 'xp': 2301},
      {'level': 8, 'xp': 3001},
      {'level': 9, 'xp': 4001},
    ];
  }

  Widget _buildAchievementsRecentSection() {
    if (_unlockedAchievements.isEmpty) return const SizedBox.shrink();
    final recent = [..._unlockedAchievements]
      ..sort(
        (a, b) => (b.unlockedAt ?? DateTime(1970)).compareTo(
          a.unlockedAt ?? DateTime(1970),
        ),
      );
    final top3 = recent.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conquistas Recentes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF005954),
            ),
          ),
          const SizedBox(height: 12),
          ...top3.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFF005954)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (a.unlockedAt != null)
                          Text(
                            'Desbloqueada em ${_formatDate(a.unlockedAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '+${a.xpReward} XP',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMissionsAndWeekly() async {
    try {
      await _missionsService.prepareTodayMissions();
      final todayMissions = await _missionsService.getTodayMissions();
      final weekly = await _weeklyService.getWeeklyChallengesWithProgress();
      final upcoming = await _weeklyService.getUpcomingChallenges();
      final recent = await _weeklyService.getRecentChallenges();

      if (!mounted || _isDisposed) return;
      setState(() {
        _todayMissions = todayMissions;
        _weeklyProgress = weekly;
        _upcoming = upcoming;
        _recent = recent;
      });
    } catch (_) {}
  }

  Widget _buildXpHistory() {
    if (_recentXp.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimos ganhos de XP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF005954),
            ),
          ),
          const SizedBox(height: 10),
          ..._recentXp.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: Color(0xFF005954),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row['description'] as String? ??
                          (row['transaction_type'] as String? ?? 'XP'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '+${row['xp_amount']} XP',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCta() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compartilhe sua citação do dia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF005954),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envie uma citação ou versículo e ganhe XP na missão de compartilhamento.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final quote = _todaysQuote.isNotEmpty
                  ? _todaysQuote
                  : await HomeService(
                      Supabase.instance.client,
                    ).getTodaysQuote();
              if (!mounted) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuoteScreen(
                    citation: quote['citation'],
                    author: quote['author'],
                  ),
                ),
              );
              if (!mounted) return;
              await _refreshGamificationData();
              await _refreshMissionsAndWeekly();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005954),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar citação'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(DateTime? lastActivity) {
    if (lastActivity == null) return 'Inativo';
    final days = DateTime.now().difference(lastActivity).inDays;
    if (days <= 7) return 'Ativo';
    if (days <= 30) return 'Parcialmente ativo';
    return 'Inativo';
  }

  bool _isLevelReached(int level, int currentLevel) {
    return level <= currentLevel;
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(0, '🎯', 'Diárias'),
          _buildTabItem(1, '🏆', 'Semanais'),
          _buildTabItem(2, '🏅', 'Conquistas'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String emoji, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDailyTab();
      case 1:
        return _buildWeeklyTab();
      case 2:
        return _buildAchievementsTab();
      default:
        return _buildDailyTab();
    }
  }

  Widget _buildDailyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDailyMissionsSection(),
          const SizedBox(height: 16),
          _buildShareCta(),
          const SizedBox(height: 16),
          _buildXpHistory(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeeklyChallengesSection(),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAchievementsRecentSection(),
          const SizedBox(height: 16),
          _buildMilestoneList(),
        ],
      ),
    );
  }
}
