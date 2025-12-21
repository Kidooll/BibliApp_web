import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/reading_plans/models/reading_plan.dart';
import 'package:bibli_app/core/services/log_service.dart';

class ReadingPlansService {
  final SupabaseClient _client;

  ReadingPlansService(this._client);

  Future<List<ReadingPlan>> getPlans() async {
    try {
      final response = await _client
          .from('reading_plans')
          .select()
          .order('duration_days');

      return (response as List)
          .map((json) => ReadingPlan.fromJson(json))
          .toList();
    } catch (e, stack) {
      LogService.error('Erro ao buscar planos', e, stack, 'ReadingPlansService');
      return [];
    }
  }

  Future<Map<int, int>> getPopularityCounts() async {
    try {
      final rows = await _client
          .from('user_reading_plan_progress')
          .select('reading_plan_id');
      if (rows.isEmpty) {
        return await _getLegacyPopularityCounts();
      }
      final counts = <int, int>{};
      for (final row in rows as List<dynamic>) {
        final planId = (row as Map<String, dynamic>)['reading_plan_id'] as int?;
        if (planId == null) continue;
        counts[planId] = (counts[planId] ?? 0) + 1;
      }
      return counts;
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar popularidade de planos',
        e,
        stack,
        'ReadingPlansService',
      );
      return {};
    }
  }

  Future<ReadingPlan?> getPlanById(int planId) async {
    try {
      final response = await _client
          .from('reading_plans')
          .select()
          .eq('id', planId)
          .single();

      return ReadingPlan.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<ReadingProgress?> getPlanProgress(
    String userId,
    int planId,
    int totalDays,
  ) async {
    try {
      final progressRow = await _client
          .from('user_reading_plan_progress')
          .select('id, completed_at, reward_claimed_at')
          .eq('user_profile_id', userId)
          .eq('reading_plan_id', planId)
          .maybeSingle();
      final progressId = progressRow?['id'] as int?;
      final completedAt = progressRow?['completed_at'];
      final rewardClaimedAt = _parseDateTime(progressRow?['reward_claimed_at']);
      if (progressId == null) {
        return null;
      }
      if (completedAt != null) {
        return ReadingProgress(
          planId: planId,
          totalDays: totalDays,
          completedDays: _buildCompleteDays(totalDays),
          rewardClaimedAt: rewardClaimedAt,
        );
      }

      final stats = await _getCompletedDaysForProgress(progressId, planId);
      if (stats.completedDays.isNotEmpty) {
        return ReadingProgress(
          planId: planId,
          totalDays: totalDays,
          completedDays: stats.completedDays,
          rewardClaimedAt: rewardClaimedAt,
        );
      }

      // Plano iniciado mas sem itens concluídos ainda.
      return ReadingProgress(
        planId: planId,
        totalDays: totalDays,
        completedDays: <int>{},
        rewardClaimedAt: rewardClaimedAt,
      );
    } catch (e) {
      return null;
    }
  }

  Future<Map<int, ReadingProgress>> getProgressMap(
    String userId,
    List<ReadingPlan> plans,
  ) async {
    try {
      final durationsByPlan = {
        for (final plan in plans) plan.id: plan.duration,
      };

      final progressRows = await _client
          .from('user_reading_plan_progress')
          .select('id, reading_plan_id, completed_at')
          .eq('user_profile_id', userId);
      final progressIds = <int>[];
      final progressByPlan = <int, int>{};
      final completedPlans = <int>{};
      for (final row in progressRows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final progressId = map['id'] as int?;
        final planId = map['reading_plan_id'] as int?;
        final completedAt = map['completed_at'];
        if (progressId == null || planId == null) continue;
        progressIds.add(progressId);
        progressByPlan[planId] = progressId;
        if (completedAt != null) {
          completedPlans.add(planId);
        }
      }

      final completedByPlan = <int, Set<int>>{};
      final itemProgressCountByPlan = <int, int>{};
      final totalByPlanDay = <int, Map<int, int>>{};
      final completedCountByPlanDay = <int, Map<int, int>>{};

      if (completedPlans.isNotEmpty) {
        for (final planId in completedPlans) {
          final totalDays = durationsByPlan[planId] ?? 0;
          completedByPlan[planId] = _buildCompleteDays(totalDays);
        }
      }

      if (durationsByPlan.isNotEmpty) {
        final itemsRows = await _client
            .from('reading_plan_items')
            .select('reading_plan_id, day_number')
            .inFilter('reading_plan_id', durationsByPlan.keys.toList());
        for (final row in itemsRows as List<dynamic>) {
          final map = row as Map<String, dynamic>;
          final planId = (map['reading_plan_id'] as num?)?.toInt();
          final day = (map['day_number'] as num?)?.toInt();
          if (planId == null || day == null) continue;
          totalByPlanDay.putIfAbsent(planId, () => <int, int>{});
          totalByPlanDay[planId]![day] = (totalByPlanDay[planId]![day] ?? 0) + 1;
        }
      }

      if (progressIds.isNotEmpty) {
        final completedRows = await _client
            .from('user_reading_plan_item_progress')
            .select(
              'user_reading_plan_progress_id, reading_plan_items(day_number, reading_plan_id)',
            )
            .inFilter('user_reading_plan_progress_id', progressIds);
        for (final row in completedRows as List<dynamic>) {
          final map = row as Map<String, dynamic>;
          final item = map['reading_plan_items'] as Map<String, dynamic>?;
          if (item == null) continue;
          final day = (item['day_number'] as num?)?.toInt();
          final planId = (item['reading_plan_id'] as num?)?.toInt();
          if (day == null || planId == null) continue;
          itemProgressCountByPlan[planId] =
              (itemProgressCountByPlan[planId] ?? 0) + 1;
          if (!completedPlans.contains(planId)) {
            completedCountByPlanDay.putIfAbsent(planId, () => <int, int>{});
            completedCountByPlanDay[planId]![day] =
                (completedCountByPlanDay[planId]![day] ?? 0) + 1;
          }
        }
      }

      for (final entry in totalByPlanDay.entries) {
        final planId = entry.key;
        if (completedPlans.contains(planId)) continue;
        final totals = entry.value;
        final completedCounts = completedCountByPlanDay[planId] ?? {};
        for (final dayEntry in totals.entries) {
          final day = dayEntry.key;
          final totalCount = dayEntry.value;
          final completedCount = completedCounts[day] ?? 0;
          if (totalCount > 0 && completedCount >= totalCount) {
            completedByPlan.putIfAbsent(planId, () => <int>{});
            completedByPlan[planId]!.add(day);
          }
        }
      }

      final map = <int, ReadingProgress>{};
      for (final plan in plans) {
        final totalDays = durationsByPlan[plan.id] ?? 0;
        final completedDays = completedByPlan[plan.id] ?? <int>{};
        if (progressByPlan.containsKey(plan.id)) {
          final hasItemProgress = (itemProgressCountByPlan[plan.id] ?? 0) > 0;
          map[plan.id] = ReadingProgress(
            planId: plan.id,
            totalDays: totalDays,
            completedDays: hasItemProgress ? completedDays : <int>{},
          );
          continue;
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  Future<ReadingPlanNextChapter?> getNextUnreadChapter(
    String userId,
    int planId,
  ) async {
    try {
      final progressId = await _ensureProgressId(userId, planId);
      final items = await _client
          .from('reading_plan_items')
          .select(
            'id, day_number, book_name, chapter_number, verses(book_id, chapter_number, books(name))',
          )
          .eq('reading_plan_id', planId)
          .order('day_number', ascending: true)
          .order('chapter_number', referencedTable: 'verses', ascending: true);
      if (items.isEmpty) {
        return null;
      }

      final readIds = <int>{};
      if (progressId != null) {
        final readRows = await _client
            .from('user_reading_plan_item_progress')
            .select('reading_plan_item_id')
            .eq('user_reading_plan_progress_id', progressId);
        for (final row in readRows as List<dynamic>) {
          final itemId =
              (row as Map<String, dynamic>)['reading_plan_item_id'] as int?;
          if (itemId != null) {
            readIds.add(itemId);
          }
        }
      }

      for (final row in items as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final itemId = (map['id'] as num?)?.toInt();
        if (itemId == null || readIds.contains(itemId)) {
          continue;
        }
        final day = (map['day_number'] as num?)?.toInt();
        final verse = map['verses'] as Map<String, dynamic>?;
        final bookId = (verse?['book_id'] as num?)?.toInt();
        final chapter = (map['chapter_number'] as num?)?.toInt() ??
            (verse?['chapter_number'] as num?)?.toInt();
        final book = verse?['books'] as Map<String, dynamic>?;
        final bookName =
            map['book_name']?.toString() ?? book?['name']?.toString();
        if (day == null || chapter == null || bookName == null) {
          continue;
        }
        return ReadingPlanNextChapter(
          planId: planId,
          dayNumber: day,
          bookId: bookId,
          bookName: bookName,
          chapterNumber: chapter,
        );
      }

      return null;
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar próximo capítulo não lido',
        e,
        stack,
        'ReadingPlansService',
      );
      return null;
    }
  }

  Future<void> markChapterAsRead({
    required String userId,
    required int planId,
    required int chapterNumber,
    int? bookId,
    String? bookName,
  }) async {
    try {
      final progressId = await _ensureProgressId(userId, planId);
      if (progressId == null) return;

      List<dynamic> rows = [];
      if (bookName != null && bookName.trim().isNotEmpty) {
        rows = await _client
            .from('reading_plan_items')
            .select('id')
            .eq('reading_plan_id', planId)
            .eq('chapter_number', chapterNumber)
            .ilike('book_name', bookName);
      }
      if (rows.isEmpty && bookId != null) {
        rows = await _client
            .from('reading_plan_items')
            .select('id, verses!inner(book_id, chapter_number)')
            .eq('reading_plan_id', planId)
            .eq('verses.book_id', bookId)
            .eq('verses.chapter_number', chapterNumber);
      }
      if (rows.isEmpty) return;

      final itemIds = <int>[];
      for (final row in rows) {
        final itemId = (row as Map<String, dynamic>)['id'] as int?;
        if (itemId != null) {
          itemIds.add(itemId);
        }
      }
      if (itemIds.isEmpty) return;

      final existing = await _client
          .from('user_reading_plan_item_progress')
          .select('reading_plan_item_id')
          .eq('user_reading_plan_progress_id', progressId)
          .inFilter('reading_plan_item_id', itemIds);
      final existingIds = <int>{};
      for (final row in existing as List<dynamic>) {
        final itemId =
            (row as Map<String, dynamic>)['reading_plan_item_id'] as int?;
        if (itemId != null) {
          existingIds.add(itemId);
        }
      }

      final now = DateTime.now().toIso8601String();
      final payload = <Map<String, dynamic>>[];
      for (final itemId in itemIds) {
        if (existingIds.contains(itemId)) continue;
        payload.add({
          'user_reading_plan_progress_id': progressId,
          'reading_plan_item_id': itemId,
          'completed_at': now,
          'created_at': now,
          'updated_at': now,
        });
      }
      if (payload.isEmpty) return;
      await _client.from('user_reading_plan_item_progress').insert(payload);
      await _touchProgress(progressId);
    } catch (e, stack) {
      LogService.error(
        'Erro ao marcar capítulo como lido',
        e,
        stack,
        'ReadingPlansService',
      );
    }
  }

  Future<bool> claimPlanReward({
    required String userId,
    required int planId,
    required int xpAmount,
    required int coinAmount,
  }) async {
    try {
      final response = await _client.rpc(
        'claim_reading_plan_reward',
        params: {
          'p_plan_id': planId,
          'p_xp_amount': xpAmount,
          'p_coin_amount': coinAmount,
        },
      );
      return response == true;
    } catch (e, stack) {
      LogService.error(
        'Erro ao resgatar recompensa do plano',
        e,
        stack,
        'ReadingPlansService',
      );
      return false;
    }
  }

  Future<void> startPlan(String userId, int planId) async {
    try {
      final existing = await _client
          .from('user_reading_plan_progress')
          .select('id')
          .eq('user_profile_id', userId)
          .eq('reading_plan_id', planId)
          .maybeSingle();
      if (existing != null) return;
      await _client.from('user_reading_plan_progress').insert({
        'user_profile_id': userId,
        'reading_plan_id': planId,
        'started_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> markDayAsRead(String userId, int planId, int day) async {
    try {
      final progress = await _client
          .from('user_reading_plan_progress')
          .select('id')
          .eq('user_profile_id', userId)
          .eq('reading_plan_id', planId)
          .maybeSingle();
      var progressId = progress?['id'] as int?;
      if (progressId == null) {
        await startPlan(userId, planId);
        final created = await _client
            .from('user_reading_plan_progress')
            .select('id')
            .eq('user_profile_id', userId)
            .eq('reading_plan_id', planId)
            .maybeSingle();
        progressId = created?['id'] as int?;
      }

      if (progressId != null) {
        final items = await _client
            .from('reading_plan_items')
            .select('id')
            .eq('reading_plan_id', planId)
            .eq('day_number', day);
        if (items.isNotEmpty) {
          for (final row in items as List<dynamic>) {
            final itemId = (row as Map<String, dynamic>)['id'] as int?;
            if (itemId == null) continue;
            final existing = await _client
                .from('user_reading_plan_item_progress')
                .select('id')
                .eq('user_reading_plan_progress_id', progressId)
                .eq('reading_plan_item_id', itemId)
                .maybeSingle();
            if (existing != null) continue;
            await _client.from('user_reading_plan_item_progress').insert({
              'user_reading_plan_progress_id': progressId,
              'reading_plan_item_id': itemId,
              'completed_at': DateTime.now().toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
          await _touchProgress(progressId);
          return;
        }
      }
      // Nenhum item encontrado para o dia; não gravar em tabela legada compartilhada.
    } catch (_) {}
  }

  Future<_DayCompletionStats> _getCompletedDaysForProgress(
    int progressId,
    int planId,
  ) async {
    try {
      final totalsRows = await _client
          .from('reading_plan_items')
          .select('day_number')
          .eq('reading_plan_id', planId);
      final totalByDay = <int, int>{};
      for (final row in totalsRows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final day = (map['day_number'] as num?)?.toInt();
        if (day == null) continue;
        totalByDay[day] = (totalByDay[day] ?? 0) + 1;
      }

      final rows = await _client
          .from('user_reading_plan_item_progress')
          .select('reading_plan_items(day_number)')
          .eq('user_reading_plan_progress_id', progressId);
      final completedCount = <int, int>{};
      for (final row in rows as List<dynamic>) {
        final item = (row as Map<String, dynamic>)['reading_plan_items']
            as Map<String, dynamic>?;
        final day = (item?['day_number'] as num?)?.toInt();
        if (day == null) continue;
        completedCount[day] = (completedCount[day] ?? 0) + 1;
      }

      final completedDays = <int>{};
      for (final entry in totalByDay.entries) {
        final day = entry.key;
        final total = entry.value;
        final done = completedCount[day] ?? 0;
        if (total > 0 && done >= total) {
          completedDays.add(day);
        }
      }

      return _DayCompletionStats(
        completedDays: completedDays,
        hasAnyProgress: rows.isNotEmpty,
      );
    } catch (_) {
      return _DayCompletionStats(
        completedDays: <int>{},
        hasAnyProgress: false,
      );
    }
  }

  Future<Map<int, int>> _getLegacyPopularityCounts() async {
    try {
      final rows =
          await _client.from('reading_progress').select('plan_id, completed');
      final counts = <int, int>{};
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        if (map['completed'] != true) continue;
        final planId = (map['plan_id'] as num?)?.toInt();
        if (planId == null) continue;
        counts[planId] = (counts[planId] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      return {};
    }
  }

  Future<void> _touchProgress(int progressId) async {
    try {
      await _client.from('user_reading_plan_progress').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', progressId);
    } catch (_) {}
  }

  DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Set<int> _buildCompleteDays(int totalDays) {
    if (totalDays <= 0) return <int>{};
    final completed = <int>{};
    for (var day = 1; day <= totalDays; day += 1) {
      completed.add(day);
    }
    return completed;
  }

  Future<int?> _ensureProgressId(String userId, int planId) async {
    try {
      final progress = await _client
          .from('user_reading_plan_progress')
          .select('id')
          .eq('user_profile_id', userId)
          .eq('reading_plan_id', planId)
          .maybeSingle();
      var progressId = progress?['id'] as int?;
      if (progressId != null) return progressId;
      await startPlan(userId, planId);
      final created = await _client
          .from('user_reading_plan_progress')
          .select('id')
          .eq('user_profile_id', userId)
          .eq('reading_plan_id', planId)
          .maybeSingle();
      progressId = created?['id'] as int?;
      return progressId;
    } catch (_) {
      return null;
    }
  }
}

class _DayCompletionStats {
  final Set<int> completedDays;
  final bool hasAnyProgress;

  _DayCompletionStats({
    required this.completedDays,
    required this.hasAnyProgress,
  });
}
