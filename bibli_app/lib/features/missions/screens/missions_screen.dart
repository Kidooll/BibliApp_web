import 'dart:async';
import 'package:flutter/material.dart';
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
  StreamSubscription<String>? _gamificationSub;
  bool _isRefreshing = false;
  bool _isDisposed = false;
  int _selectedTabIndex = 0; // 0: Diárias, 1: Semanais, 2: Conquistas

  Level? _currentLevel;
  int _totalXp = 0;
  int _xpToNextLevel = 0;
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
      final todaysQuote = await HomeService(
        Supabase.instance.client,
      ).getTodaysQuote();

      // Carregar dados
      final totalXp = await GamificationService.getTotalXp();
      final currentLevel = await GamificationService.getCurrentLevelInfo();
      final xpToNextLevel = await GamificationService.getXpToNextLevel();
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
          _unlockedAchievements = unlockedAchievements;
          _userStats = userStats;
          _levels = levels;
          _coins = coins;
          _recentXp = recentXp;
          _username = username;
          _todaysQuote = todaysQuote;
          _todayMissions = todayMissions;
          _weeklyProgress = weekly;
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SafeArea(
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
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  String _missionTypeLabel(String type) {
    switch (type) {
      case ChallengeTypes.reading:
      case ChallengeTypes.legacyReadingTypo:
        return 'Leitura';
      case ChallengeTypes.legacyShare:
      case ChallengeTypes.sharing:
        return 'Compartilhar';
      case ChallengeTypes.study:
        return 'Estudo';
      case ChallengeTypes.plan:
        return 'Plano';
      case ChallengeTypes.devotionals:
      case ChallengeTypes.legacyDevotional:
        return 'Devocional';
      case ChallengeTypes.goal:
        return 'Meta';
      case ChallengeTypes.favorite:
        return 'Favorito';
      case ChallengeTypes.note:
        return 'Nota';
      case 'streak':
        return 'Sequência';
      case 'habit':
        return 'Hábito';
      default:
        return 'Geral';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
        final claimed = row['is_claimed'] == true;
        final xp = ch['xp_reward'] as int? ?? 0;
        final type =
            ch['challenge_type'] as String? ?? ChallengeTypes.reading;

        final pct = (target > 0) ? (progress / target).clamp(0, 1).toDouble() : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Progress Ring
                SizedBox(
                  width: 58,
                  height: 58,
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: done ? Colors.green : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getChallengeIcon(type),
                          color: Colors.white,
                          size: 18,
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
                          fontSize: 14,
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
                          _chip(
                            label: '$progress/$target',
                            color: AppColors.primary,
                            background: AppColors.primary.withOpacity(0.12),
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            label: '+$xp XP',
                            color: Colors.green,
                            background: Colors.green.withOpacity(0.12),
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            label: _missionTypeLabel(type),
                            color: const Color(0xFF2F5E5B),
                            background: const Color(0xFFEAF2FF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botão de ação
                if (done && !claimed)
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await _weeklyService.claimChallenge(
                        row['id'] as int,
                      );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Resgatar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (done && claimed)
                  _chip(
                    label: 'Resgatado',
                    color: Colors.green,
                    background: Colors.green.withOpacity(0.12),
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
      case ChallengeTypes.reading:
      case ChallengeTypes.legacyReadingTypo:
        return Icons.menu_book;
      case ChallengeTypes.sharing:
      case ChallengeTypes.legacyShare:
        return Icons.share;
      case ChallengeTypes.study:
        return Icons.school;
      case ChallengeTypes.plan:
        return Icons.auto_stories;
      case ChallengeTypes.devotionals:
      case ChallengeTypes.legacyDevotional:
        return Icons.book;
      case ChallengeTypes.goal:
        return Icons.flag;
      case ChallengeTypes.favorite:
        return Icons.favorite;
      case ChallengeTypes.note:
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: claimed
                  ? Colors.green.withOpacity(0.4)
                  : canClaim
                      ? AppColors.primary.withOpacity(0.4)
                      : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Ícone da missão
                Container(
                  width: 48,
                  height: 48,
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
                    size: 22,
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
                          fontSize: 14,
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
                      Row(
                        children: [
                          _chip(
                            label: '+$xp XP',
                            color: claimed
                                ? Colors.green
                                : canClaim
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                            background: (claimed
                                    ? Colors.green
                                    : canClaim
                                        ? AppColors.primary
                                        : Colors.grey)
                                .withOpacity(0.12),
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            label: _missionTypeLabel(missionType),
                            color: const Color(0xFF2F5E5B),
                            background: const Color(0xFFEAF2FF),
                          ),
                        ],
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
                      'Em progresso',
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
      case ChallengeTypes.legacyDevotional:
        return Icons.menu_book;
      case ChallengeTypes.legacyShare:
        return Icons.share;
      case 'streak':
        return Icons.local_fire_department;
      case ChallengeTypes.reading:
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
    const requirements = LevelRequirements.requirements;
    final clampedLevel = currentLevelNumber.clamp(1, requirements.length);
    final currentIdx = clampedLevel - 1;
    final prevThreshold = requirements[currentIdx];
    int nextThreshold;
    if (currentIdx + 1 < requirements.length) {
      nextThreshold = requirements[currentIdx + 1];
    } else {
      final fallbackDelta = _xpToNextLevel > 0
          ? _xpToNextLevel
          : LevelRequirements.defaultXpToNextLevel;
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
                              ? m.description
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
    const thresholds = LevelRequirements.requirements;
    return [
      {
        'level': '1',
        'title': 'Novato na Fé',
        'description': 'Iniciou a jornada espiritual (0-${thresholds[1] - 1} XP)',
      },
      {
        'level': '2',
        'title': 'Buscador',
        'description':
            'Em busca de conhecimento (${thresholds[1]}-${thresholds[2] - 1} XP)',
      },
      {
        'level': '3',
        'title': 'Discípulo',
        'description':
            'Comprometido com o aprendizado (${thresholds[2]}-${thresholds[3] - 1} XP)',
      },
      {
        'level': '4',
        'title': 'Servo Fiel',
        'description':
            'Dedicado à prática diária (${thresholds[3]}-${thresholds[4] - 1} XP)',
      },
      {
        'level': '5',
        'title': 'Estudioso',
        'description':
            'Conhecedor das Escrituras (${thresholds[4]}-${thresholds[5] - 1} XP)',
      },
      {
        'level': '6',
        'title': 'Sábio',
        'description':
            'Sabedoria espiritual (${thresholds[5]}-${thresholds[6] - 1} XP)',
      },
      {
        'level': '7',
        'title': 'Mestre',
        'description':
            'Mestre na Palavra (${thresholds[6]}-${thresholds[7] - 1} XP)',
      },
      {
        'level': '8',
        'title': 'Líder Espiritual',
        'description':
            'Líder e exemplo (${thresholds[7]}-${thresholds[8] - 1} XP)',
      },
      {
        'level': '9',
        'title': 'Mentor',
        'description':
            'Guia de outros (${thresholds[8]}-${thresholds[9] - 1} XP)',
      },
      {
        'level': '10',
        'title': 'Gigante da Fé',
        'description': 'Máximo nível espiritual (${thresholds[9]}+ XP)',
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
    return [
      for (var i = 0; i < LevelRequirements.requirements.length; i += 1)
        {'level': i + 1, 'xp': LevelRequirements.requirements[i]},
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

      if (!mounted || _isDisposed) return;
      setState(() {
        _todayMissions = todayMissions;
        _weeklyProgress = weekly;
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
