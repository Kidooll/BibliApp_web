import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/home/services/home_service.dart';
import 'package:bibli_app/features/home/models/user_profile.dart';
import 'package:bibli_app/core/models/devotional.dart';
import 'package:bibli_app/features/home/models/reading_streak.dart';
import 'package:bibli_app/features/devotionals/screens/devotional_screen.dart';
import 'package:bibli_app/features/devotionals/services/devotional_access_service.dart';
import 'package:bibli_app/features/quotes/screens/quote_screen.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:bibli_app/features/gamification/models/user_stats.dart';
import 'package:bibli_app/features/gamification/services/achievement_service.dart';
import 'package:bibli_app/features/gamification/services/achievement_overlay_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/core/widgets/loading_widget.dart';
import 'package:bibli_app/core/widgets/animations.dart';
import 'package:bibli_app/core/services/monitoring_service.dart';
import 'package:bibli_app/features/reading_plans/screens/reading_plans_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService(Supabase.instance.client);
  StreamSubscription? _eventsSubscription;

  UserProfile? _userProfile;
  Devotional? _todaysDevotional;
  ReadingStreak? _readingStreak;
  List<Devotional> _recentDevotionals = [];
  Map<String, String?> _todaysQuote = {};
  bool _isLoading = true;
  int _totalXp = 0;
  UserStats? _userStats;
  DateTime _selectedDate = DateTime.now();
  Devotional? _selectedDevotional;
  Map<String, String?> _selectedQuote = {};
  bool _isLoadingDate = false;
  List<Map<String, dynamic>> _pendingMissions = [];
  List<Map<String, dynamic>> _activeReadingPlans = [];

  @override
  void initState() {
    super.initState();
    MonitoringService.logScreenView('home_screen');
    _loadData();
    // Auto-refresh de XP/Stats quando houver eventos
    _eventsSubscription = GamificationService.events.listen((event) async {
      if (!mounted) return;
      if (event == 'xp_changed' ||
          event == 'level_up' ||
          event == 'streak_changed') {
        try {
          await GamificationService.forceSync();
          final totalXp = await GamificationService.getTotalXp();
          final stats = await GamificationService.getUserStats();
          if (mounted) {
            setState(() {
              _totalXp = totalXp;
              _userStats = stats;
            });
          }
        } catch (e) {
          // Ignora erros de sincronização
        }
      } else if (event == 'achievements_unlocked') {
        // Verificar novas conquistas e mostrar notificações
        try {
          final achievements = await AchievementService.getAchievements();
          final newAchievements = achievements.where((a) => 
            a.isUnlocked && 
            a.unlockedAt != null &&
            DateTime.now().difference(a.unlockedAt!).inSeconds < 10
          ).toList();
          
          if (newAchievements.isNotEmpty && mounted) {
            AchievementOverlayService.showMultipleAchievements(
              context, 
              newAchievements,
            );
          }
        } catch (e) {
          // Ignora erros de conquistas
        }
      }
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await GamificationService.initialize();
      await GamificationService.syncIfStale();
      await GamificationService.repairStreakFromHistoryIfNeeded();

      // Garantir que o perfil do usuário existe
      await _homeService.ensureUserProfile();

      // Carregar dados em paralelo para melhor performance
      final futures = await Future.wait([
        _homeService.getUserProfile(user.id),
        _homeService.getTodaysDevotional(),
        _homeService.getReadingStreak(user.id),
        _homeService.getRecentDevotionals(),
        _homeService.getTodaysQuote(),
        GamificationService.getTotalXp(),
        GamificationService.getUserStats(),
        _loadPendingMissions(),
        _loadActiveReadingPlans(),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = futures[0] as UserProfile?;
          _todaysDevotional = futures[1] as Devotional?;
          _readingStreak = futures[2] as ReadingStreak?;
          _recentDevotionals = futures[3] as List<Devotional>;
          _todaysQuote = futures[4] as Map<String, String?>;
          _totalXp = futures[5] as int;
          _userStats = futures[6] as UserStats?;
          _pendingMissions = futures[7] as List<Map<String, dynamic>>;
          _activeReadingPlans = futures[8] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(
          message: 'Carregando dados...',
          showShimmer: true,
        ),
      );
    }

    // Verificar se o usuário está autenticado
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Usuário não autenticado'));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com saudação
              AnimatedEntry(
                delay: const Duration(milliseconds: 100),
                child: _buildHeader(),
              ),
              const SizedBox(height: 24),

              // Card de progresso do usuário
              AnimatedEntry(
                delay: const Duration(milliseconds: 200),
                child: _buildProgressCard(),
              ),
              const SizedBox(height: 24),

              // Seletor de data
              AnimatedEntry(
                delay: const Duration(milliseconds: 300),
                child: _buildDateSelector(),
              ),
              const SizedBox(height: 24),

              // Card de conteúdo diário
              AnimatedEntry(
                delay: const Duration(milliseconds: 400),
                child: _buildDailyContentCard(),
              ),
              const SizedBox(height: 24),

              // Recomendações do editor
              AnimatedEntry(
                delay: const Duration(milliseconds: 500),
                child: _buildEditorRecommendations(),
              ),
            ],
          ),
        ),
      ),
    ),    
    );
  }

  Widget _buildHeader() {
    try {
      final greeting = _homeService.getGreeting();
      final userName = _userProfile?.username ?? 'Usuário';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE0E0E0),
                  backgroundImage: (_userProfile?.avatarUrl?.trim().isNotEmpty ?? false)
                      ? NetworkImage(_userProfile!.avatarUrl!)
                      : null,
                  child: (_userProfile?.avatarUrl?.trim().isEmpty ?? true)
                      ? Text(
                          userName.isNotEmpty
                              ? userName.characters.first.toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF2D2D2D),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$greeting, $userName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Desejamos que tenha um $greeting',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      );
    } catch (e) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Desejamos que tenha um bom dia',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      );
    }
  }

  Widget _buildProgressCard() {
    try {
      final userProfile = _userProfile;
      if (userProfile == null) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF338b85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'Carregando perfil...',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      final currentXp = _totalXp;
      final currentLevel = (_userProfile?.currentLevel ?? 1).clamp(1, 10);
      
      // Usar os níveis corretos do PRD (10 níveis)
      const requirements = LevelRequirements.requirements;
      
      // Calcular threshold anterior e próximo
      final previousThreshold = currentLevel > 1 
          ? requirements[currentLevel - 1] 
          : 0;
      final nextThreshold = currentLevel < 10 
          ? requirements[currentLevel] 
          : requirements[9] + 1000; // Nível máximo
      
      final totalForLevel = nextThreshold - previousThreshold;
      final currentXpInLevel = (currentXp - previousThreshold).clamp(0, totalForLevel);
      final progress = totalForLevel > 0 ? currentXpInLevel / totalForLevel : 1.0;

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF5E9EA0), Color(0xFF5E9EA0), Color(0xFF1F4549)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nível e XP
              Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  FutureBuilder<String>(
                    future: _homeService.getLevelName(userProfile.currentLevel),
                    builder: (context, snapshot) {
                      return Text(
                        'Nível ${userProfile.currentLevel} - ${snapshot.data ?? 'Buscador'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Text(
                    '$currentXp XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              // Estatísticas rápidas
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sequência: ${_userStats?.currentStreakDays ?? 0} dias',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recorde: ${_userStats?.longestStreakDays ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Devocionais lidos: ${userProfile.totalDevotionalsRead}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Semana: ${_weekProgress()}/${_userProfile?.weeklyGoal ?? 7}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(height: 24, color: Colors.white.withOpacity(0.2)),
              // Missões em aberto
              const Row(
                children: [
                  Icon(Icons.flag, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Missões em aberto:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_pendingMissions.isEmpty)
                const Row(
                  children: [
                    SizedBox(width: 28),
                    Icon(Icons.circle_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Você não iniciou nenhuma missão ainda.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                )
              else
                ..._pendingMissions.map((mission) {
                  final missionData = mission['daily_missions'] as Map<String, dynamic>?;
                  final title = missionData?['title'] as String? ?? 'Missão';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 28),
                        const Icon(Icons.circle_outlined, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              Divider(height: 24, color: Colors.white.withOpacity(0.2)),
              // Planos de leitura ativos
              const Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Planos de leitura:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  SizedBox(width: 28),
                  Icon(Icons.bookmark_border, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Você não iniciou nenhum plano de leitura.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF338b85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Erro ao carregar progresso',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    final weekday = now.weekday;
    final daysFromSunday = weekday == 7 ? 0 : weekday;
    final startOfWeek = now.subtract(Duration(days: daysFromSunday));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showFullCalendar,
          child: Row(
            children: [
              Text(
                _getMonthName(_selectedDate.month),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final dayDate = startOfWeek.add(Duration(days: index));
            final dayNumber = dayDate.day;
            final isToday =
                dayDate.day == now.day &&
                dayDate.month == now.month &&
                dayDate.year == now.year;
            final isSelected =
                dayDate.day == _selectedDate.day &&
                dayDate.month == _selectedDate.month &&
                dayDate.year == _selectedDate.year;
            final isCurrentMonth = dayDate.month == now.month;
            final isFuture = dayDate.isAfter(now);

            return GestureDetector(
              onTap: isFuture ? null : () => _onDateSelected(dayDate),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF005954) : Colors.transparent,
                  border: isToday && !isSelected
                      ? Border.all(color: const Color(0xFF005954), width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : (isFuture
                                ? Colors.grey.shade300
                                : (isCurrentMonth ? Colors.grey : Colors.grey.shade300)),
                      ),
                    ),
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isFuture
                                ? Colors.grey.shade300
                                : (isCurrentMonth ? const Color(0xFF2D2D2D) : Colors.grey.shade300)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDailyContentCard() {
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;
    
    final displayDevotional = isToday ? _todaysDevotional : _selectedDevotional;
    final displayQuote = isToday ? _todaysQuote : _selectedQuote;
    final dateLabel = isToday ? 'Hoje' : '${_selectedDate.day}/${_selectedDate.month}';

    if (_isLoadingDate) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF338b85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF338b85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Citação do dia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Citação - $dateLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuoteScreen(
                        citation: displayQuote['citation'],
                        author: displayQuote['author'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayQuote['citation'] ??
                'Os desafios são os lances do destino, que nos preparam para a nossa grandeza.',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Devocional
          FutureBuilder<bool>(
            future: displayDevotional != null
                ? _canAccessDevotional(displayDevotional)
                : Future.value(false),
            builder: (context, snapshot) {
              final canAccess = snapshot.data ?? false;
              final isChecking =
                  snapshot.connectionState == ConnectionState.waiting;
              final hasDevotional = displayDevotional != null;

              final titleText = hasDevotional
                  ? (canAccess
                      ? displayDevotional.title
                      : 'Devocional bloqueado')
                  : 'Nenhum devocional disponível para esta data';
              final verseText = (hasDevotional && canAccess)
                  ? (displayDevotional.verse1 ??
                      'O Senhor é bom para com aqueles cuja esperança está nele, para com aqueles que o buscam;')
                  : 'Conclua a leitura do dia anterior para desbloquear.';
              final verseRef = (hasDevotional && canAccess)
                  ? (displayDevotional.verse2 ?? 'Lamentações 3:25')
                  : '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Devocional - $dateLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (hasDevotional)
                        ElevatedButton(
                          onPressed: (!isChecking && canAccess)
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DevotionalScreen(
                                        devotionalId: displayDevotional.id,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAccess
                                ? Colors.white
                                : Colors.grey.shade400,
                            foregroundColor: canAccess
                                ? const Color(0xFF005954)
                                : Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                canAccess ? Icons.menu_book : Icons.lock,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isChecking
                                    ? 'Verificando'
                                    : (canAccess ? 'Ler' : 'Bloqueado'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    titleText,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Versículo do dia
                  const Row(
                    children: [
                      Icon(Icons.menu_book, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Versículo do Dia',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verseText,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (verseRef.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      verseRef,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditorRecommendations() {
    const planCards = [
      (
        title: 'Salmos em 30 Dias',
        description: '150 capítulos',
        icon: Icons.auto_stories,
        color: Color(0xFF5E9EA0),
      ),
      (
        title: 'Provérbios',
        description: '31 capítulos',
        icon: Icons.lightbulb_outline,
        color: Color(0xFF7B9E89),
      ),
      (
        title: 'Novo Testamento',
        description: '260 capítulos',
        icon: Icons.menu_book,
        color: Color(0xFF8B7E74),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Planos de Leitura',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadingPlansScreen(),
                  ),
                );
              },
              child: const Text(
                'Ver todos',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: planCards.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final card = planCards[index];
              return _buildReadingPlanCard(
                title: card.title,
                description: card.description,
                icon: card.icon,
                color: card.color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadingPlanCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReadingPlansScreen(),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
  }

  Future<bool> _canAccessDevotional(Devotional devotional) async {
    final accessService =
        DevotionalAccessService(Supabase.instance.client);
    return accessService.canAccessDevotional(
      devotionalId: devotional.id,
      publishedDate: devotional.publishedDate,
    );
  }

  int _weekProgress() {
    final goal = _userProfile?.weeklyGoal ?? 7;
    final streak = _userStats?.currentStreakDays ?? 0;
    return streak.clamp(0, goal);
  }

  Future<List<Map<String, dynamic>>> _loadPendingMissions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final today = DateTime.now().toIso8601String().split('T')[0];
      final res = await Supabase.instance.client
          .from('user_missions')
          .select('id, status, daily_missions(title)')
          .eq('user_id', user.id)
          .eq('mission_date', today)
          .eq('status', 'pending')
          .limit(3);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadActiveReadingPlans() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      // Por enquanto retorna vazio até implementar tabela de planos
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _isLoadingDate = true;
    });

    try {
      final devotional = await _homeService.getDevotionalByDate(date);
      final quote = await _homeService.getQuoteByDate(date);

      if (mounted) {
        setState(() {
          _selectedDevotional = devotional;
          _selectedQuote = quote;
          _isLoadingDate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDate = false;
        });
      }
    }
  }

  Future<void> _showFullCalendar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final readDates = await _homeService.getReadDates(user.id);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _CalendarDialog(
        selectedDate: _selectedDate,
        readDates: readDates,
        onDateSelected: (date) {
          Navigator.pop(context);
          _onDateSelected(date);
        },
      ),
    );
  }
}

class _CalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Set<DateTime> readDates;
  final Function(DateTime) onDateSelected;

  const _CalendarDialog({
    required this.selectedDate,
    required this.readDates,
    required this.onDateSelected,
  });

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() {
        _currentMonth = nextMonth;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isRead(DateTime date) {
    return widget.readDates.any((d) => _isSameDay(d, date));
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = (constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width * 0.9) -
              32; // padding horizontal (16*2)
          final cellSize = (availableWidth / 7).clamp(32.0, 48.0).toDouble();

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Dias da semana
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                      .map((day) => SizedBox(
                            width: cellSize,
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),
                // Grid de dias
                ...List.generate((daysInMonth + firstWeekday) ~/ 7 + 1, (weekIndex) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (dayIndex) {
                      final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return SizedBox(width: cellSize, height: cellSize);
                      }

                      final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                      final isToday = _isSameDay(date, now);
                      final isSelected = _isSameDay(date, widget.selectedDate);
                      final isRead = _isRead(date);
                      final isFuture = date.isAfter(now);

                      return GestureDetector(
                        onTap: isFuture ? null : () => widget.onDateSelected(date),
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF005954)
                                : (isRead ? const Color(0xFF338b85).withOpacity(0.3) : null),
                            border: isToday && !isSelected
                                ? Border.all(color: const Color(0xFF005954), width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isFuture ? Colors.grey.shade300 : Colors.black),
                                    fontWeight: isRead ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isRead && !isSelected)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF005954),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                }),
                const SizedBox(height: 12),
                // Legenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegend(Colors.grey.shade300, 'Hoje'),
                    _buildLegend(const Color(0xFF338b85).withOpacity(0.3), 'Lido'),
                    _buildLegend(const Color(0xFF005954), 'Selecionado'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return months[month - 1];
  }
}
