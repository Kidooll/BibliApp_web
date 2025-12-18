import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase Configuration (carregado do .env)
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    
    if (url.isEmpty) {
      throw StateError(
        'SUPABASE_URL não configurada no arquivo .env\n'
        'Adicione: SUPABASE_URL=https://seu-projeto.supabase.co',
      );
    }
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw StateError(
        'SUPABASE_URL inválida: $url\n'
        'Deve começar com https:// ou http://',
      );
    }
    
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    if (key.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY não configurada no arquivo .env',
      );
    }
    
    if (key.length < 32) {
      throw StateError('SUPABASE_ANON_KEY muito curta (mínimo 32 caracteres)');
    }
    
    return key;
  }

  // App Configuration
  static const String appName = 'BibliApp';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String bollsApiUrl = 'https://bolls.life/api/';

  // Contact Information
  static const String privacyEmail = 'privacidade@bibliapp.com';

  static void ensureSupabaseConfig() {
    // Validação já é feita nos getters
    final _ = supabaseUrl;
    final __ = supabaseAnonKey;
  }
}
