import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';

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
    await supabase.auth.signInWithPassword(email: email, password: password);
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

      print('Cache local limpo com sucesso');
    } catch (e) {
      print('Erro ao limpar cache local: $e');
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
      throw AuthException('Falha ao criar conta');
    }

    // Criar perfil do usuário automaticamente
    try {
      await supabase.from('user_profiles').insert({
        'id': response.user!.id,
        'username': name,
        'total_devotionals_read': 0,
        'total_xp': 0,
        'current_level': 1,
        'xp_to_next_level': 100,
        'coins': 0,
        'weekly_goal': 7,
      });
    } catch (e) {
      print('Erro ao criar perfil do usuário: $e');
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
          'xp_to_next_level': 100,
          'coins': 0,
          'weekly_goal': 7,
        });
      }
    } catch (e) {
      print('Erro ao verificar/criar perfil do usuário: $e');
    }
  }
}
