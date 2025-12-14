import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/home/models/user_profile.dart';
import 'package:bibli_app/features/home/models/devotional.dart';
import 'package:bibli_app/features/home/models/reading_streak.dart';

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
    } catch (e) {
      print('Erro ao verificar/criar perfil do usuário: $e');
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
    } catch (e) {
      print('Erro ao buscar perfil do usuário: $e');
      return null;
    }
  }

  Future<Devotional?> getTodaysDevotional() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await supabase
          .from('devotionals')
          .select()
          .eq('published_date', today)
          .maybeSingle();

      if (response != null) {
        return Devotional.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar devocional do dia: $e');
      return null;
    }
  }

  Future<Map<String, String?>> getTodaysQuote() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
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
    } catch (e) {
      print('Erro ao buscar citação do dia: $e');
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
    } catch (e) {
      print('Erro ao buscar streak de leitura: $e');
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
    } catch (e) {
      print('Erro ao buscar devocionais recentes: $e');
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
}
