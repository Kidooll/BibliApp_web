import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/features/reading_plans/models/reading_plan.dart';
import 'package:bibli_app/features/reading_plans/services/reading_plans_service.dart';
import 'package:bibli_app/features/reading_plans/screens/reading_plan_detail_screen.dart';

class ReadingPlansScreen extends StatefulWidget {
  const ReadingPlansScreen({super.key});

  @override
  State<ReadingPlansScreen> createState() => _ReadingPlansScreenState();
}

class _ReadingPlansScreenState extends State<ReadingPlansScreen> {
  final _service = ReadingPlansService(Supabase.instance.client);
  List<ReadingPlan> _plans = [];
  Map<int, ReadingProgress> _progressByPlan = {};
  Map<int, int> _popularityByPlan = {};
  bool _loading = true;
  int _selectedFilter = 0;
  String _selectedSort = 'Mais Popular';
  String _displayName = 'Usuário';

  static const double _filterHeight = 30;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    final plans = await _service.getPlans();
    final popularity = await _service.getPopularityCounts();
    final user = Supabase.instance.client.auth.currentUser;
    Map<int, ReadingProgress> progress = {};
    var displayName = 'Usuário';
    if (user != null) {
      progress = await _service.getProgressMap(user.id, plans);
      displayName = user.userMetadata?['name']?.toString().trim() ?? '';
      if (displayName.isEmpty) {
        try {
          final profile = await Supabase.instance.client
              .from('user_profiles')
              .select('username')
              .eq('id', user.id)
              .maybeSingle();
          final username = profile?['username']?.toString().trim() ?? '';
          if (username.isNotEmpty) {
            displayName = username;
          }
        } catch (_) {}
      }
      if (displayName.isEmpty) {
        displayName = user.email?.toString().trim() ?? 'Usuário';
      }
    }
    if (mounted) {
      setState(() {
        _popularityByPlan = popularity;
        _plans = _applySort(plans);
        _progressByPlan = progress;
        _displayName = displayName;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _displayName.toString().trim().split(' ').first;
    final inProgress = _plans
        .where((plan) {
          final progress = _progressByPlan[plan.id];
          return progress != null && progress.percentage < 100;
        })
        .toList();
    final completed = _plans
        .where((plan) {
          final progress = _progressByPlan[plan.id];
          return progress != null && progress.percentage >= 100;
        })
        .toList();
    final available = _plans
        .where((plan) {
          final progress = _progressByPlan[plan.id];
          return progress == null;
        })
        .toList();
    final showOnlyCompleted = _selectedFilter == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlans,
          color: AppColors.primary,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildHeaderCard(firstName),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 20),
                    Text(
                      showOnlyCompleted ? 'Concluídos' : 'Em Progresso',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0E3E3C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (showOnlyCompleted && completed.isEmpty)
                      const Text(
                        'Você ainda não concluiu um plano.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF6B7480),
                        ),
                      )
                    else if (inProgress.isEmpty && !showOnlyCompleted)
                      const Text(
                        'Você ainda não iniciou um plano.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF6B7480),
                        ),
                      )
                    else
                      ...(showOnlyCompleted ? completed : inProgress).map(
                        (plan) {
                          final progress = _progressByPlan[plan.id];
                          final showProgressCard =
                              progress != null && progress.percentage < 100;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: showOnlyCompleted
                                ? _buildProgressCard(plan, progress)
                                : (showProgressCard
                                    ? _buildProgressCard(plan, progress)
                                    : _buildPlanCard(plan)),
                          );
                        },
                      ),
                    if (!showOnlyCompleted) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Planos de Leitura',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0E3E3C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (available.isEmpty)
                        const Text(
                          'Nenhum plano disponível.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF6B7480),
                          ),
                        )
                      else
                        ...available.map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildPlanCard(plan),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String firstName) {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF8FB8B5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Olá $firstName!',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha um plano e mergulhe\nna Palavra de Deus!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, size: 18),
              color: const Color(0xFF3B5E5C),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip(
          label: 'Todos',
          selected: _selectedFilter == 0,
          onSelected: () => setState(() => _selectedFilter = 0),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: 'Concluídos',
          selected: _selectedFilter == 1,
          onSelected: () => setState(() => _selectedFilter = 1),
        ),
        const Spacer(),
        Container(
          height: _filterHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSort,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B5E5C),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Mais Popular',
                  child: Text('Mais Popular'),
                ),
                DropdownMenuItem(
                  value: 'Mais Recentes',
                  child: Text('Mais Recentes'),
                ),
                DropdownMenuItem(
                  value: 'Menor Duração',
                  child: Text('Menor Duração'),
                ),
                DropdownMenuItem(
                  value: 'Maior Duração',
                  child: Text('Maior Duração'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedSort = value;
                  _plans = _applySort(_plans);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: _filterHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F5E5B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF3B5E5C),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(ReadingPlan plan, ReadingProgress? progress) {
    final day = (progress?.currentDay ?? 1).clamp(1, plan.duration);
    final percent = ((progress?.percentage ?? 0) / 100).clamp(0.0, 1.0);
    final xp = _xpForPlan(plan.duration);
    final talents = _talentsForXp(xp);
    final isCompleted = (progress?.percentage ?? 0) >= 100;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingPlanDetailScreen(plan: plan),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanIcon(plan, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3F3D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dia $day de ${plan.duration} dias',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF6B7480),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE9EFEF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2F5E5B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '$xp XP',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF6B7480),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.circle,
                          size: 10, color: Color(0xFFD8B04E)),
                      const SizedBox(width: 4),
                      Text(
                        '$talents Talentos',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF6B7480),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isCompleted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6ECEC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Color(0xFF2F5E5B)),
                    SizedBox(width: 6),
                    Text(
                      'Concluído',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F5E5B),
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReadingPlanDetailScreen(plan: plan),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E3E3C),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Continuar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(ReadingPlan plan) {
    final xp = _xpForPlan(plan.duration);
    final talents = _talentsForXp(xp);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingPlanDetailScreen(plan: plan),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanIcon(plan, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F3F3D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF6B7480),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '$xp XP',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF6B7480),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.circle,
                                size: 10, color: Color(0xFFD8B04E)),
                            const SizedBox(width: 4),
                            Text(
                              '$talents Talentos',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF6B7480),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${plan.duration} Dias',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF6B7480),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '0%',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF6B7480),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 0,
                            minHeight: 6,
                            backgroundColor: Color(0xFFE9EFEF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2F5E5B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadingPlanDetailScreen(
                            plan: plan,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E3E3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Iniciar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanIcon(ReadingPlan plan, {double size = 46}) {
    final asset = _planIconAsset(plan.title);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: asset == null
          ? const Icon(Icons.auto_stories, color: Color(0xFF3B5E5C))
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
    );
  }

  int _xpForPlan(int duration) {
    if (duration <= 14) return 100;
    if (duration <= 30) return 150;
    if (duration <= 40) return 175;
    if (duration <= 60) return 200;
    if (duration <= 90) return 250;
    return 300;
  }

  int _talentsForXp(int xp) {
    if (xp <= 110) return 5;
    if (xp <= 160) return 7;
    if (xp <= 190) return 9;
    if (xp <= 230) return 11;
    return 15;
  }

  List<ReadingPlan> _applySort(List<ReadingPlan> plans) {
    final sorted = [...plans];
    switch (_selectedSort) {
      case 'Mais Recentes':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Menor Duração':
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'Maior Duração':
        sorted.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      default:
        sorted.sort((a, b) {
          final countA = _popularityByPlan[a.id] ?? 0;
          final countB = _popularityByPlan[b.id] ?? 0;
          final compare = countB.compareTo(countA);
          if (compare != 0) return compare;
          return a.duration.compareTo(b.duration);
        });
    }
    return sorted;
  }

  String? _planIconAsset(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('salmos')) {
      return 'assets/images/reading_plans/icon_03.png';
    }
    if (lower.contains('profetas')) {
      return 'assets/images/reading_plans/icon_05.png';
    }
    if (lower.contains('provérbios') || lower.contains('proverbios')) {
      return 'assets/images/reading_plans/icon_01.png';
    }
    if (lower.contains('evangelho') || lower.contains('evangelhos')) {
      return 'assets/images/reading_plans/icon_02.png';
    }
    if (lower.contains('gênesis') || lower.contains('genesis')) {
      return 'assets/images/reading_plans/icon_04.png';
    }
    return 'assets/images/reading_plans/icon_01.png';
  }
}
