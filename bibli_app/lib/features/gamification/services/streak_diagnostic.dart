import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StreakDiagnostic {
  static const String _context = 'StreakDiagnostic';

  /// Executa diagnóstico completo do sistema de streaks
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final results = <String, dynamic>{};
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        results['error'] = 'Usuário não autenticado';
        return results;
      }

      // 1. Verificar user_stats
      final userStats = await GamificationService.getUserStats();
      results['user_stats'] = {
        'exists': userStats != null,
        'current_streak': userStats?.currentStreakDays ?? 0,
        'longest_streak': userStats?.longestStreakDays ?? 0,
        'total_devotionals': userStats?.totalDevotionalsRead ?? 0,
        'last_activity': userStats?.lastActivityDate?.toIso8601String(),
      };

      // 2. Verificar reading_streaks
      final readingStreaks = await Supabase.instance.client
          .from('reading_streaks')
          .select()
          .eq('user_profile_id', user.id)
          .maybeSingle();
      
      results['reading_streaks'] = {
        'exists': readingStreaks != null,
        'current_streak': readingStreaks?['current_streak_days'] ?? 0,
        'longest_streak': readingStreaks?['longest_streak_days'] ?? 0,
        'last_active': readingStreaks?['last_active_date'],
      };

      // 3. Verificar read_devotionals (últimos 30 dias)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final readDevotionals = await Supabase.instance.client
          .from('read_devotionals')
          .select('read_date, read_at')
          .eq('user_profile_id', user.id)
          .gte('read_at', thirtyDaysAgo.toIso8601String())
          .order('read_at', ascending: false);

      final uniqueDays = <String>{};
      for (final row in readDevotionals) {
        final date = row['read_date'] ?? row['read_at'];
        if (date != null) {
          final dateStr = date.toString().split('T')[0];
          uniqueDays.add(dateStr);
        }
      }

      results['read_devotionals'] = {
        'total_reads_30_days': readDevotionals.length,
        'unique_days_30_days': uniqueDays.length,
        'days': uniqueDays.toList()..sort((a, b) => b.compareTo(a)),
      };

      // 4. Calcular streak esperada
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      int expectedStreak = 0;
      if (uniqueDays.isNotEmpty) {
        final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));
        final lastDay = sortedDays.first;
        
        // Verificar se última leitura foi hoje ou ontem
        final lastDate = DateTime.parse(lastDay);
        final daysDiff = today.difference(lastDate).inDays;
        
        if (daysDiff <= 1) {
          // Contar dias consecutivos
          DateTime checkDate = lastDate;
          for (final day in sortedDays) {
            final dayDate = DateTime.parse(day);
            final diff = checkDate.difference(dayDate).inDays;
            
            if (diff == 0) {
              expectedStreak++;
              continue;
            } else if (diff == 1) {
              expectedStreak++;
              checkDate = dayDate;
            } else {
              break;
            }
          }
        }
      }

      results['calculated_streak'] = expectedStreak;
      results['today'] = todayStr;
      results['has_read_today'] = uniqueDays.contains(todayStr);

      // 5. Verificar bônus de streak
      final xpTransactions = await Supabase.instance.client
          .from('xp_transactions')
          .select('transaction_type, xp_amount, created_at')
          .eq('user_id', user.id)
          .eq('transaction_type', 'streak_bonus')
          .order('created_at', ascending: false)
          .limit(10);

      results['streak_bonuses'] = xpTransactions.map((tx) => {
        'xp': tx['xp_amount'],
        'date': tx['created_at'],
      }).toList();

      // 6. Verificar consistência
      final isConsistent = 
          (userStats?.currentStreakDays ?? 0) == (readingStreaks?['current_streak_days'] ?? 0);
      
      results['consistency_check'] = {
        'is_consistent': isConsistent,
        'user_stats_streak': userStats?.currentStreakDays ?? 0,
        'reading_streaks_streak': readingStreaks?['current_streak_days'] ?? 0,
        'calculated_streak': expectedStreak,
        'needs_repair': !isConsistent || 
            (userStats?.currentStreakDays ?? 0) != expectedStreak,
      };

      LogService.info('Diagnóstico de streak concluído', _context);
      
    } catch (e, stack) {
      LogService.error('Erro no diagnóstico de streak', e, stack, _context);
      results['error'] = e.toString();
    }

    return results;
  }

  /// Imprime diagnóstico formatado
  static void printDiagnostic(Map<String, dynamic> results) {
    LogService.info('=== DIAGNÓSTICO DE STREAK ===', _context);
    
    if (results.containsKey('error')) {
      LogService.error('Erro: ${results['error']}', null, null, _context);
      return;
    }

    final userStats = results['user_stats'] as Map<String, dynamic>;
    final readingStreaks = results['reading_streaks'] as Map<String, dynamic>;
    final readDevotionals = results['read_devotionals'] as Map<String, dynamic>;
    final consistency = results['consistency_check'] as Map<String, dynamic>;

    LogService.info('USER_STATS:', _context);
    LogService.info('  Existe: ${userStats['exists']}', _context);
    LogService.info('  Streak Atual: ${userStats['current_streak']}', _context);
    LogService.info('  Maior Streak: ${userStats['longest_streak']}', _context);
    LogService.info('  Total Lidos: ${userStats['total_devotionals']}', _context);

    LogService.info('READING_STREAKS:', _context);
    LogService.info('  Existe: ${readingStreaks['exists']}', _context);
    LogService.info('  Streak Atual: ${readingStreaks['current_streak']}', _context);

    LogService.info('READ_DEVOTIONALS (30 dias):', _context);
    LogService.info('  Total Leituras: ${readDevotionals['total_reads_30_days']}', _context);
    LogService.info('  Dias Únicos: ${readDevotionals['unique_days_30_days']}', _context);
    LogService.info('  Leu Hoje: ${results['has_read_today']}', _context);

    LogService.info('CÁLCULO:', _context);
    LogService.info('  Streak Calculada: ${results['calculated_streak']}', _context);

    LogService.info('CONSISTÊNCIA:', _context);
    LogService.info('  Consistente: ${consistency['is_consistent']}', _context);
    LogService.info('  Precisa Reparo: ${consistency['needs_repair']}', _context);

    if (consistency['needs_repair'] == true) {
      LogService.warning('⚠️ Sistema de streak precisa de reparo!', _context);
      LogService.info('Execute: GamificationService.repairStreakFromHistoryIfNeeded()', _context);
    } else {
      LogService.info('✅ Sistema de streak funcionando corretamente!', _context);
    }
  }

  /// Executa e imprime diagnóstico
  static Future<void> runAndPrint() async {
    final results = await runDiagnostic();
    printDiagnostic(results);
  }
}
