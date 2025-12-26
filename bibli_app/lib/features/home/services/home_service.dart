import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/home/models/user_profile.dart';
import 'package:bibli_app/features/home/models/devotional.dart';
import 'package:bibli_app/features/home/models/reading_streak.dart';
import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/core/services/server_time_service.dart';
import 'package:bibli_app/features/devotionals/services/devotional_access_service.dart';

class HomeService {
  final SupabaseClient supabase;

  HomeService(this.supabase);

  Future<void> ensureUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Verificar se o perfil existe
      final profile = await supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        // Criar perfil se não existir
        await supabase.from('user_profiles').insert({
          'id': user.id,
          'username': user.userMetadata?['name'] ?? 'Usuário',
          'total_devotionals_read': 0,
          'total_xp': 0,
          'current_level': 1,
          'xp_to_next_level': 100,
          'coins': 0,
          'weekly_goal': 7,
        });
      }
    } catch (e, stack) {
      LogService.error(
        'Erro ao verificar/criar perfil do usuário',
        e,
        stack,
        'HomeService',
      );
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar perfil do usuário',
        e,
        stack,
        'HomeService',
      );
      return null;
    }
  }

  Future<Devotional?> getTodaysDevotional() async {
    try {
      final today = await ServerTimeService.getSaoPauloDate(supabase);
      if (today == null) return null;
      final response = await supabase
          .from('devotionals')
          .select()
          .eq('published_date', today)
          .maybeSingle();

      if (response != null) {
        return Devotional.fromJson(response);
      }
      return null;
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar devocional do dia',
        e,
        stack,
        'HomeService',
      );
      return null;
    }
  }

  Future<Map<String, String?>> getTodaysQuote() async {
    try {
      final today = await ServerTimeService.getSaoPauloDate(supabase);
      if (today == null) {
        return {
          'citation': 'Nenhuma citação disponível no momento.',
          'author': null,
        };
      }
      final response = await supabase
          .from('devotionals')
          .select('citation, author')
          .eq('published_date', today)
          .maybeSingle();

      if (response != null) {
        return {'citation': response['citation'], 'author': response['author']};
      }
      return {
        'citation': 'A esperança é o sonho do homem acordado.',
        'author': 'Aristóteles',
      };
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar citação do dia',
        e,
        stack,
        'HomeService',
      );
      return {
        'citation': 'A esperança é o sonho do homem acordado.',
        'author': 'Aristóteles',
      };
    }
  }

  Future<ReadingStreak?> getReadingStreak(String userId) async {
    try {
      final response = await supabase
          .from('reading_streaks')
          .select()
          .eq('user_profile_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return ReadingStreak.fromJson(response);
      }
      return null;
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar streak de leitura',
        e,
        stack,
        'HomeService',
      );
      return null;
    }
  }

  Future<List<Devotional>> getRecentDevotionals({int limit = 5}) async {
    try {
      final response = await supabase
          .from('devotionals')
          .select()
          .order('published_date', ascending: false)
          .limit(limit);

      return response.map((json) => Devotional.fromJson(json)).toList();
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar devocionais recentes',
        e,
        stack,
        'HomeService',
      );
      return [];
    }
  }

  Future<String> getLevelName(int level) async {
    // Mapeamento de níveis baseado no PRD
    final levelNames = {
      1: 'Novato na Fé',
      2: 'Buscador',
      3: 'Discípulo',
      4: 'Servo Fiel',
      5: 'Estudioso',
      6: 'Sábio',
      7: 'Mestre',
      8: 'Líder Espiritual',
      9: 'Mentor',
      10: 'Gigante da Fé',
    };

    return levelNames[level] ?? 'Nível $level';
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia';
    } else if (hour < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  Future<Devotional?> getDevotionalByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final today = await ServerTimeService.getSaoPauloDate(supabase);
      if (today == null || dateStr.compareTo(today) > 0) {
        return null;
      }
      final response = await supabase
          .from('devotionals')
          .select()
          .eq('published_date', dateStr)
          .maybeSingle();

      if (response != null) {
        final devotional = Devotional.fromJson(response);
        final accessService = DevotionalAccessService(supabase);
        final canAccess = await accessService.canAccessDevotional(
          devotionalId: devotional.id,
          publishedDate: devotional.publishedDate,
        );
        if (!canAccess) return null;
        return devotional;
      }
      return null;
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar devocional da data $date',
        e,
        stack,
        'HomeService',
      );
      return null;
    }
  }

  Future<Map<String, String?>> getQuoteByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await supabase
          .from('devotionals')
          .select('citation, author')
          .eq('published_date', dateStr)
          .maybeSingle();

      if (response != null) {
        return {'citation': response['citation'], 'author': response['author']};
      }
      return {
        'citation': 'Nenhuma citação disponível para esta data.',
        'author': null,
      };
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar citação da data $date',
        e,
        stack,
        'HomeService',
      );
      return {
        'citation': 'Erro ao carregar citação.',
        'author': null,
      };
    }
  }

  Future<Set<DateTime>> getReadDates(String userId) async {
    try {
      final response = await supabase
          .from('reading_history')
          .select('read_at')
          .eq('user_id', userId)
          .order('read_at', ascending: false);

      return response.map((item) {
        final dateStr = item['read_at'] as String;
        return DateTime.parse(dateStr);
      }).toSet();
    } catch (e, stack) {
      LogService.error(
        'Erro ao buscar datas de leitura',
        e,
        stack,
        'HomeService',
      );
      return {};
    }
  }
}
