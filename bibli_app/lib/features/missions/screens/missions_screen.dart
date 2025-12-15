import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/gamification/models/achievement.dart';
import '../../../features/gamification/models/level.dart';
import '../../../features/gamification/models/user_stats.dart';
import '../../../features/gamification/services/gamification_service.dart';
import '../services/missions_service.dart';
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
  List<Level> _levels = [];
  int _coins = 0;
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
      final levels = await _fetchLevels();
      final coins = await _fetchCoins();

      setState(() {
        _totalXp = totalXp;
        _currentLevel = currentLevel;
        _xpToNextLevel = xpToNextLevel;
        _achievements = achievements;
        _unlockedAchievements = unlockedAchievements;
        _userStats = userStats;
        _levels = levels;
        _coins = coins;
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

  Future<List<Level>> _fetchLevels() async {
    try {
      final res = await Supabase.instance.client
          .from('levels')
          .select()
          .order('level_number');
      return List<Map<String, dynamic>>.from(res)
          .map((e) => Level.fromJson(e))
          .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF005954)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 12),
                  _buildXpCard(),
                  const SizedBox(height: 16),
                  _buildMilestoneList(),
                  const SizedBox(height: 16),
                  _buildDailyMissionsSection(),
                  const SizedBox(height: 16),
                  _buildWeeklyChallengesSection(),
                  const SizedBox(height: 16),
                  _buildAchievementsRecentSection(),
                ],
              ),
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

  Widget _buildHeaderCard() {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['name'] ?? user?.email ?? 'Usuário';
    final initials = _getInitials(displayName);
    final levelNumber = _currentLevel?.levelNumber ?? 0;
    final achievementsCount = _unlockedAchievements.length;
    final streak = _userStats?.currentStreakDays ?? 0;

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
            'Inactive Member',
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
              _buildStatMini(label: 'Moedas', value: '$_coins'),
              Container(width: 1, height: 24, color: Colors.white24),
              _buildStatMini(
                label: 'Conquistas',
                value: '$achievementsCount',
              ),
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
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
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
    int idx = thresholds.indexWhere((t) => (t['level'] ?? 0) == currentLevelNumber);
    if (idx == -1) {
      idx = thresholds.indexWhere((t) => (t['level'] ?? 0) > currentLevelNumber);
    }
    if (idx == -1) idx = thresholds.length - 1;

    final prevThreshold = idx > 0 ? thresholds[idx - 1]['xp'] as int : 0;
    // Próximo limiar: usa entrada seguinte; se não houver, usa XP atual + xpToNextLevel
    int nextThreshold;
    if (idx + 1 < thresholds.length) {
      nextThreshold = thresholds[idx + 1]['xp'] as int;
    } else {
      final fallbackDelta = _xpToNextLevel > 0 ? _xpToNextLevel : 200;
      nextThreshold = _totalXp + fallbackDelta;
    }

    final totalForLevel = (nextThreshold - prevThreshold).clamp(1, 1 << 31);
    final progress =
        ((_totalXp - prevThreshold) / totalForLevel).clamp(0.0, 1.0).toDouble();

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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
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
          ...milestones.map(
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
        'title': 'Buscador',
        'description': 'Descrição: Iniciou a jornada em busca de Deus.',
      },
      {
        'level': '5',
        'title': 'Discípulo',
        'description':
            'Descrição: Comprometido com o aprendizado e a prática diária.',
      },
      {
        'level': '10',
        'title': 'Guardião da Fé',
        'description': 'Descrição: Defensor da verdade e fiel à Palavra.',
      },
      {
        'level': '15',
        'title': 'Sábio Espiritual',
        'description': 'Descrição: Conhecedor das Escrituras.',
      },
      {
        'level': '20',
        'title': 'Mensageiro Divino',
        'description':
            'Descrição: Compartilha a Palavra com ousadia e amor.',
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
    // fallback
    return [
      {'level': 0, 'xp': 0},
      {'level': 1, 'xp': 150},
      {'level': 2, 'xp': 400},
      {'level': 3, 'xp': 750},
      {'level': 4, 'xp': 1200},
      {'level': 5, 'xp': 1700},
    ];
  }

  Widget _buildAchievementsRecentSection() {
    if (_unlockedAchievements.isEmpty) return const SizedBox.shrink();
    final recent = [..._unlockedAchievements]
      ..sort((a, b) => (b.unlockedAt ?? DateTime(1970))
          .compareTo(a.unlockedAt ?? DateTime(1970)));
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
}
