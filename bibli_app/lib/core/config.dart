class AppConfig {
  // Supabase Configuration (carregado via --dart-define em tempo de build)
  static final String supabaseUrl =
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static final String supabaseAnonKey =
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // App Configuration
  static const String appName = 'BibliApp';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String bollsApiUrl = 'https://bolls.life/api/';

  // Contact Information
  static const String privacyEmail = 'privacidade@bibliapp.com';

  static void ensureSupabaseConfig() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Configuração do Supabase ausente. Defina SUPABASE_URL e SUPABASE_ANON_KEY via --dart-define.',
      );
    }
  }
}
