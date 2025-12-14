import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:badges/badges.dart' as badges;
import '../../../features/gamification/services/gamification_service.dart';
import '../../../features/gamification/models/level.dart';
import '../../../features/gamification/models/achievement.dart';
import '../../../features/gamification/models/user_stats.dart';
import '../services/missions_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/weekly_challenges_service.dart';

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

  Level? _currentLevel;
  int _totalXp = 0;
  int _xpToNextLevel = 0;
  List<Achievement> _achievements = [];
  List<Achievement> _unlockedAchievements = [];
  UserStats? _userStats;
  bool _isLoading = true;
  List<Map<String, dynamic>> _todayMissions = [];
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
    GamificationService.events.listen((event) {
      if (!mounted) return;
      if (event == 'achievement_unlocked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Conquista desbloqueada!'),
            duration: Duration(seconds: 2),
          ),
        );
        // Iniciar uma pequena animação visual (reutilizando _levelUpController)
        _levelUpController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    _levelUpController.dispose();
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

      _missionsService = MissionsService(Supabase.instance.client);
      _weeklyService = WeeklyChallengesService(Supabase.instance.client);
      await _missionsService.prepareTodayMissions();
      final todayMissions = await _missionsService.getTodayMissions();
      final weekly = await _weeklyService.getWeeklyChallengesWithProgress();
      final upcoming = await _weeklyService.getUpcomingChallenges();
      final recent = await _weeklyService.getRecentChallenges();

      // Carregar dados
      final totalXp = await GamificationService.getTotalXp();
      final currentLevel = await GamificationService.getCurrentLevelInfo();
      final xpToNextLevel = await GamificationService.getXpToNextLevel();
      final achievements = await GamificationService.getAllAchievements();
      final unlockedAchievements =
          await GamificationService.getUserAchievements();
      final userStats = await GamificationService.getUserStats();

      setState(() {
        _totalXp = totalXp;
        _currentLevel = currentLevel;
        _xpToNextLevel = xpToNextLevel;
        _achievements = achievements;
        _unlockedAchievements = unlockedAchievements;
        _userStats = userStats;
        _todayMissions = todayMissions;
        _weeklyProgress = weekly;
        _upcoming = upcoming;
        _recent = recent;
        _isLoading = false;
      });

      // Iniciar animação da barra de XP
      _xpAnimationController.forward();
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF005954)),
              )
            : CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF005954),
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Missões & Conquistas',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF005954), Color(0xFF007A6B)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Conteúdo
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card de Progresso
                          _buildProgressCard(),
                          const SizedBox(height: 24),

                          // Estatísticas
                          _buildStatsCard(),
                          const SizedBox(height: 24),

                          // Conquistas
                          _buildAchievementsSection(),
                          const SizedBox(height: 24),
                          _buildWeeklyChallengesSection(),
                          const SizedBox(height: 24),
                          _buildWeeklyUpcomingSection(),
                          const SizedBox(height: 24),
                          _buildWeeklyRecentSection(),
                          const SizedBox(height: 24),
                          _buildDailyMissionsSection(),
                        ],
                      ),
                    ),
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
    final levelRequirements = [0, 150, 400, 750, 1200];
    if (level >= 5) return 0;
    return levelRequirements[level] - levelRequirements[level - 1];
  }

  int _getCurrentXpInLevel(int level) {
    final levelRequirements = [0, 150, 400, 750, 1200];
    if (level >= 5) return 0;
    final levelStartXp = levelRequirements[level - 1];
    return _totalXp - levelStartXp;
  }

  Widget _buildWeeklyChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desafios Semanais',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005954),
          ),
        ),
        const SizedBox(height: 12),
        if (_weeklyProgress.isEmpty)
          const Text('Nenhum desafio semanal ativo.')
        else
          Column(
            children: _weeklyProgress.map((row) {
              final ch =
                  row['weekly_challenges'] as Map<String, dynamic>? ?? {};
              final title = ch['title'] as String? ?? 'Desafio';
              final description = ch['description'] as String? ?? '';
              final target = ch['target_value'] as int? ?? 1;
              final progress = row['current_progress'] as int? ?? 0;
              final done = row['is_completed'] == true;
              final xp = ch['xp_reward'] as int? ?? 0;

              final pct = (target > 0)
                  ? (progress / target).clamp(0, 1).toDouble()
                  : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(description),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF005954),
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progresso: $progress/$target'),
                          done
                              ? ElevatedButton(
                                  onPressed: () async {
                                    final ok = await _weeklyService
                                        .claimChallenge(row['id'] as int);
                                    if (ok && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Recompensa semanal: +$xp XP',
                                          ),
                                        ),
                                      );
                                      await _loadData();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF005954),
                                  ),
                                  child: const Text('Resgatar'),
                                )
                              : Text('Recompensa: +$xp XP'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Missões Diárias',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005954),
          ),
        ),
        const SizedBox(height: 12),
        if (_todayMissions.isEmpty)
          const Text('Nenhuma missão para hoje.')
        else
          Column(
            children: _todayMissions.map((m) {
              final status = m['status'] as String? ?? 'pending';
              final mission =
                  m['daily_missions'] as Map<String, dynamic>? ?? {};
              final title = mission['title'] as String? ?? 'Missão';
              final description = mission['description'] as String? ?? '';
              final xp = mission['xp_reward'] as int? ?? 0;
              final canClaim = status == 'completed';
              final claimed = status == 'claimed';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.flag, color: Color(0xFF005954)),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(description),
                  trailing: claimed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                          onPressed: canClaim
                              ? () async {
                                  final ok = await _missionsService
                                      .claimMission(m['id'] as int);
                                  if (!mounted) return;
                                  if (ok) {
                                    // Otimista: marca como claimed imediatamente
                                    setState(() {
                                      final idx = _todayMissions.indexWhere(
                                        (it) => it['id'] == m['id'],
                                      );
                                      if (idx != -1) {
                                        _todayMissions[idx]['status'] =
                                            'claimed';
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Recompensa resgatada: +$xp XP',
                                        ),
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                      ),
                                    );
                                    // Recarrega dados para manter consistência
                                    await _loadData();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005954),
                          ),
                          child: Text(canClaim ? 'Resgatar' : '+$xp XP'),
                        ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
