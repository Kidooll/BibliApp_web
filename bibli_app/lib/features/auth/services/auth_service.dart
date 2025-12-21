import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

class AuthService {
  final SupabaseClient supabase;

  AuthService(this.supabase);

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth
        .signInWithPassword(email: email, password: password);

    // Registrar último login/atividade para uso em status de usuário
    final user = response.user;
    if (user != null) {
      await _markLastLogin(user.id);
    }
  }

  Future<void> signOut() async {
    // Limpar todos os caches locais antes de fazer logout
    await _clearAllLocalCache();

    // Fazer logout do Supabase
    await supabase.auth.signOut();
  }

  /// Limpa todos os caches locais do app
  Future<void> _clearAllLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limpar cache de gamificação
      await GamificationService.clearCache();

      // Limpar outros caches que possam existir
      await prefs.remove('user_preferences');
      await prefs.remove('last_activity_date');
      await prefs.remove('devotional_cache');

      LogService.info('Cache local limpo', 'AuthService');
    } catch (e, stack) {
      LogService.error('Erro ao limpar cache', e, stack, 'AuthService');
    }
  }

  /// Verifica se o usuário está logado
  bool get isLoggedIn => currentUser != null;

  /// Verifica se há uma sessão ativa
  bool get hasActiveSession => supabase.auth.currentSession != null;

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    if (response.user == null) {
      throw const AuthException('Falha ao criar conta');
    }

    // Criar perfil do usuário automaticamente
    try {
      await supabase.from('user_profiles').insert({
        'id': response.user!.id,
        'username': name,
        'total_devotionals_read': 0,
        'total_xp': 0,
        'current_level': 1,
        'xp_to_next_level': LevelRequirements.initialXpToNextLevel,
        'coins': 0,
        'weekly_goal': 7,
      });
    } catch (e, stack) {
      LogService.error('Erro ao criar perfil', e, stack, 'AuthService');
      // Não vamos falhar o cadastro se o perfil não for criado
    }
  }

  Future<void> ensureUserProfile() async {
    final user = currentUser;
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
          'xp_to_next_level': LevelRequirements.initialXpToNextLevel,
          'coins': 0,
          'weekly_goal': 7,
        });
      }
    } catch (e, stack) {
      LogService.error('Erro ao verificar perfil', e, stack, 'AuthService');
    }
  }

  Future<void> _markLastLogin(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Atualiza user_stats.last_activity_date (já existe na base) e garante row
    try {
      await supabase.from('user_stats').upsert({
        'user_id': userId,
        'last_activity_date': today,
      }, onConflict: 'user_id');
    } catch (e, stack) {
      LogService.error(
        'Erro ao registrar último login em user_stats',
        e,
        stack,
        'AuthService',
      );
    }

    // Opcional: manter um carimbo em user_profiles para consultas rápidas
    try {
      await supabase
          .from('user_profiles')
          .update({'last_weekly_reset': today}).eq('id', userId);
    } catch (e) {
      // Silenciar falha; campo é opcional para essa finalidade
    }
  }
}
