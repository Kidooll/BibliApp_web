import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/home/services/home_service.dart';
import 'package:bibli_app/features/home/models/user_profile.dart';
import 'package:bibli_app/features/home/models/devotional.dart';
import 'package:bibli_app/features/home/models/reading_streak.dart';
import 'package:bibli_app/features/devotionals/screens/devotional_screen.dart';
import 'package:bibli_app/features/quotes/screens/quote_screen.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:bibli_app/features/gamification/models/user_stats.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService(Supabase.instance.client);

  UserProfile? _userProfile;
  Devotional? _todaysDevotional;
  ReadingStreak? _readingStreak;
  List<Devotional> _recentDevotionals = [];
  Map<String, String?> _todaysQuote = {};
  bool _isLoading = true;
  int _totalXp = 0;
  UserStats? _userStats;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh de XP/Stats quando houver eventos
    GamificationService.events.listen((event) async {
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
        } catch (_) {}
      }
    });
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
      await GamificationService.forceSync();
      await GamificationService.repairStreakFromHistoryIfNeeded();

      // Garantir que o perfil do usuário existe
      await _homeService.ensureUserProfile();

      final userProfile = await _homeService.getUserProfile(user.id);
      final todaysDevotional = await _homeService.getTodaysDevotional();
      final readingStreak = await _homeService.getReadingStreak(user.id);
      final recentDevotionals = await _homeService.getRecentDevotionals();
      final todaysQuote = await _homeService.getTodaysQuote();
      final totalXp = await GamificationService.getTotalXp();
      final userStats = await GamificationService.getUserStats();

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _todaysDevotional = todaysDevotional;
          _readingStreak = readingStreak;
          _recentDevotionals = recentDevotionals;
          _todaysQuote = todaysQuote;
          _totalXp = totalXp;
          _userStats = userStats;
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF005954)),
      );
    }

    // Verificar se o usuário está autenticado
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Usuário não autenticado'));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com saudação
            _buildHeader(),
            const SizedBox(height: 24),

            // Card de progresso do usuário
            _buildProgressCard(),
            const SizedBox(height: 24),

            // Seletor de data
            _buildDateSelector(),
            const SizedBox(height: 24),

            // Card de conteúdo diário
            _buildDailyContentCard(),
            const SizedBox(height: 24),

            // Recomendações do editor
            _buildEditorRecommendations(),
          ],
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
          Text(
            '$greeting, $userName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
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

      final currentXp = _totalXp; // usar XP total real
      final currentLevel = (_userProfile?.currentLevel ?? 1).clamp(1, 99);
      final thresholds = _levelThresholdsFor(currentLevel + 1);
      final previousThreshold =
          thresholds[(currentLevel - 1).clamp(0, thresholds.length - 1)];
      final nextThreshold = currentLevel >= thresholds.length - 1
          ? thresholds.last
          : thresholds[currentLevel];
      final totalForLevel = (nextThreshold - previousThreshold).clamp(
        1,
        1 << 31,
      );
      final xpToNext = currentLevel >= thresholds.length - 1
          ? 0
          : (nextThreshold - currentXp).clamp(0, totalForLevel);
      final currentXpInLevel = (currentXp - previousThreshold).clamp(
        0,
        totalForLevel,
      );
      final progress = totalForLevel > 0
          ? currentXpInLevel / totalForLevel
          : 0.0;

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
              ),
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

    // Calcular o início da semana (domingo)
    // weekday retorna 1 (segunda) a 7 (domingo), queremos 0 (domingo) a 6 (sábado)
    final weekday = now.weekday;
    final daysFromSunday = weekday == 7 ? 0 : weekday;
    final startOfWeek = now.subtract(Duration(days: daysFromSunday));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _getMonthName(now.month),
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
            final isCurrentMonth = dayDate.month == now.month;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFF005954) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday
                          ? Colors.white
                          : (isCurrentMonth
                                ? Colors.grey
                                : Colors.grey.shade300),
                    ),
                  ),
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? Colors.white
                          : (isCurrentMonth
                                ? const Color(0xFF2D2D2D)
                                : Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDailyContentCard() {
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
                  const Text(
                    'Citação do Dia',
                    style: TextStyle(
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
                        citation: _todaysQuote['citation'],
                        author: _todaysQuote['author'],
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
            _todaysQuote['citation'] ??
                'Os desafios são os lances do destino, que nos preparam para a nossa grandeza.',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Devocional de hoje
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Devocional de hoje',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DevotionalScreen(devotionalId: _todaysDevotional?.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF005954),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Ler'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _todaysDevotional?.title ?? 'Desafios como oportunidades Divinas',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Versículo do dia
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
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
          const Text(
            'O Senhor é bom para com aqueles cuja esperança está nele, para com aqueles que o buscam;',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lamentações 3:25',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendações do Editor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRecommendationCard(
                title: 'A Disciplina como...',
                imageUrl: 'assets/images/recommendation1.png',
              ),
              _buildRecommendationCard(
                title: 'A Mulher Virtuosa e...',
                imageUrl: 'assets/images/recommendation2.png',
              ),
              _buildRecommendationCard(
                title: 'Foco',
                imageUrl: 'assets/images/recommendation3.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required String title,
    required String imageUrl,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5dc1b9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, color: Colors.white, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),
        ],
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

  int _weekProgress() {
    final goal = _userProfile?.weeklyGoal ?? 7;
    final streak = _userStats?.currentStreakDays ?? 0;
    return streak.clamp(0, goal);
  }

  List<int> _levelThresholdsFor(int level) {
    final base = [0, 150, 400, 750, 1200];
    if (level < base.length) {
      return base.sublist(0, level + 1);
    }

    final thresholds = List<int>.from(base);
    var increment =
        base.last - base[base.length - 2]; // mantém padrão de crescimento
    for (int i = base.length; i <= level; i++) {
      thresholds.add(thresholds.last + increment);
      increment += 100;
    }
    return thresholds;
  }
}
