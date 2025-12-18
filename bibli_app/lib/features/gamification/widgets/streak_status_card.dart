import 'package:flutter/material.dart';
import '../services/gamification_service.dart';
import '../../../core/constants/app_constants.dart';

class StreakStatusCard extends StatelessWidget {
  const StreakStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadStreakData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data as Map<String, dynamic>;
        final currentStreak = data['current_streak'] as int;
        final longestStreak = data['longest_streak'] as int;
        final totalReads = data['total_reads'] as int;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.complementary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Status da Streak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      icon: Icons.whatshot,
                      label: 'Atual',
                      value: '$currentStreak',
                      subtitle: 'dias',
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withAlpha(77),
                    ),
                    _buildStatColumn(
                      icon: Icons.emoji_events,
                      label: 'Recorde',
                      value: '$longestStreak',
                      subtitle: 'dias',
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withAlpha(77),
                    ),
                    _buildStatColumn(
                      icon: Icons.menu_book,
                      label: 'Total',
                      value: '$totalReads',
                      subtitle: 'lidos',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStreakMessage(currentStreak),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withAlpha(204),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakMessage(int streak) {
    String message;
    IconData icon;
    
    if (streak == 0) {
      message = 'Comece sua jornada hoje!';
      icon = Icons.rocket_launch;
    } else if (streak < 3) {
      message = 'Continue assim! Você está no caminho certo.';
      icon = Icons.trending_up;
    } else if (streak < 7) {
      message = 'Ótimo progresso! Continue firme.';
      icon = Icons.star;
    } else if (streak < 30) {
      message = 'Incrível! Você está em chamas! 🔥';
      icon = Icons.whatshot;
    } else {
      message = 'Lendário! Você é um exemplo! 👑';
      icon = Icons.emoji_events;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStreakData() async {
    final userStats = await GamificationService.getUserStats();
    
    return {
      'current_streak': userStats?.currentStreakDays ?? 0,
      'longest_streak': userStats?.longestStreakDays ?? 0,
      'total_reads': userStats?.totalDevotionalsRead ?? 0,
    };
  }
}
