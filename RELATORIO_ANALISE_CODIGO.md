# 📋 Relatório de Análise de Código - BibliApp

**Data:** 2024
**Arquivos Analisados:** 49 arquivos Dart
**Versão:** 1.0.0

---

## 🔴 PRIORIDADE CRÍTICA: Segurança e Validação de Dados

### 1. **Exposição de Credenciais do Supabase**
**Localização:** `lib/core/config.dart` (linhas 3-6)
**Severidade:** 🔴 CRÍTICA

**Problema:**
```dart
static final String supabaseUrl =
    const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
static final String supabaseAnonKey =
    const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
```

**Impacto:**
- Se as variáveis de ambiente não forem definidas, o app falha silenciosamente
- Não há validação se as chaves são válidas
- Risco de commit acidental de credenciais

**Correção Sugerida:**
```dart
class AppConfig {
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    if (url.isEmpty) {
      throw StateError('SUPABASE_URL não configurada');
    }
    if (!url.startsWith('https://')) {
      throw StateError('SUPABASE_URL deve usar HTTPS');
    }
    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (key.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY não configurada');
    }
    if (key.length < 32) {
      throw StateError('SUPABASE_ANON_KEY inválida');
    }
    return key;
  }
}
```

---

### 2. **Validação de Email Inadequada**
**Localização:** `lib/features/auth/screens/signup_screen.dart` (linha 42)
**Severidade:** 🟠 ALTA

**Problema:**
```dart
_isEmailValid = _emailController.text.trim().isNotEmpty && 
                _emailController.text.contains('@');
```

**Impacto:**
- Aceita emails inválidos como "a@", "@domain", "user@"
- Permite caracteres especiais perigosos
- Não valida formato RFC 5322

**Correção Sugerida:**
```dart
bool _isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  return emailRegex.hasMatch(email.trim());
}

void _validateEmail() {
  setState(() {
    _isEmailValid = _isValidEmail(_emailController.text);
  });
}
```

---

### 3. **Senha Fraca Permitida**
**Localização:** `lib/features/auth/screens/signup_screen.dart` (linha 48)
**Severidade:** 🟠 ALTA

**Problema:**
```dart
_isPasswordValid = _passwordController.text.length >= 6;
```

**Impacto:**
- Permite senhas fracas como "123456", "aaaaaa"
- Não exige complexidade (maiúsculas, números, símbolos)
- Vulnerável a ataques de força bruta

**Correção Sugerida:**
```dart
bool _isStrongPassword(String password) {
  if (password.length < 8) return false;
  
  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
  final hasLowercase = password.contains(RegExp(r'[a-z]'));
  final hasDigits = password.contains(RegExp(r'[0-9]'));
  final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  
  return hasUppercase && hasLowercase && hasDigits && hasSpecialChar;
}

void _validatePassword() {
  setState(() {
    _isPasswordValid = _isStrongPassword(_passwordController.text);
  });
}
```

---

### 4. **Tratamento de Erros Silencioso**
**Localização:** Múltiplos arquivos
**Severidade:** 🟠 ALTA

**Exemplos:**
- `lib/features/quotes/screens/quote_screen.dart` (linha 145): `catch (_) {}`
- `lib/features/devotionals/services/devotional_service.dart` (linha 107): `catch (_) {}`
- `lib/features/auth/services/auth_service.dart` (linha 48): `print('Erro...')`

**Impacto:**
- Erros críticos são ignorados
- Dificulta debugging em produção
- Usuário não recebe feedback adequado

**Correção Sugerida:**
```dart
// Criar serviço de logging centralizado
class LogService {
  static void logError(String context, dynamic error, [StackTrace? stack]) {
    debugPrint('❌ [$context] $error');
    if (stack != null) debugPrint(stack.toString());
    
    // Em produção, enviar para serviço como Sentry/Firebase Crashlytics
    if (kReleaseMode) {
      // FirebaseCrashlytics.instance.recordError(error, stack);
    }
  }
}

// Uso:
try {
  await service.completeMissionByCode('share_quote');
} catch (e, stack) {
  LogService.logError('QuoteScreen._shareQuote', e, stack);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao registrar missão')),
    );
  }
}
```

---

### 5. **SQL Injection Potencial**
**Localização:** `lib/features/gamification/services/gamification_service.dart`
**Severidade:** 🟡 MÉDIA

**Problema:**
Embora o Supabase use prepared statements, há concatenação de strings em queries:
```dart
.eq('user_id', user.id)
.eq('mission_id', mission['id'])
```

**Impacto:**
- Se IDs forem manipulados, pode haver injeção
- Falta validação de tipos

**Correção Sugerida:**
```dart
// Validar tipos antes de queries
String _sanitizeUserId(String userId) {
  if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(userId)) {
    throw ArgumentError('User ID inválido');
  }
  return userId;
}

int _sanitizeMissionId(dynamic id) {
  if (id is! int || id <= 0) {
    throw ArgumentError('Mission ID inválido');
  }
  return id;
}
```

---

### 6. **Armazenamento Inseguro de Dados Sensíveis**
**Localização:** `lib/features/gamification/services/gamification_service.dart` (linha 56)
**Severidade:** 🟡 MÉDIA

**Problema:**
```dart
await prefs.setString(_cacheKey, json.encode(_localCache));
```

**Impacto:**
- Dados de gamificação armazenados em texto plano
- SharedPreferences não é criptografado
- Vulnerável a acesso root/jailbreak

**Correção Sugerida:**
```dart
// Usar flutter_secure_storage para dados sensíveis
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCache {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> saveSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  static Future<String?> readSecure(String key) async {
    return await _storage.read(key: key);
  }
}
```

---

## 🟡 PRIORIDADE ALTA: Modularidade e Estrutura

### 7. **Widget Monolítico**
**Localização:** `lib/features/home/screens/home_screen.dart` (600+ linhas)
**Severidade:** 🟡 MÉDIA

**Problema:**
- Classe com mais de 600 linhas
- Múltiplas responsabilidades (UI, lógica, estado)
- Difícil manutenção e teste

**Correção Sugerida:**
```dart
// Separar em widgets menores
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Apenas gerenciamento de estado
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeHeader(userProfile: _userProfile),
              HomeProgressCard(userProfile: _userProfile, userStats: _userStats),
              HomeDateSelector(),
              HomeDailyContent(devotional: _todaysDevotional, quote: _todaysQuote),
              HomeRecommendations(devotionals: _recentDevotionals),
            ],
          ),
        ),
      ),
    );
  }
}

// Widgets separados
class HomeHeader extends StatelessWidget {
  final UserProfile? userProfile;
  const HomeHeader({required this.userProfile});
  
  @override
  Widget build(BuildContext context) {
    // Implementação
  }
}
```

---

### 8. **Falta de Separação de Camadas**
**Localização:** Todo o projeto
**Severidade:** 🟡 MÉDIA

**Problema:**
- Lógica de negócio misturada com UI
- Services acessam diretamente Supabase.instance.client
- Não há camada de repository/domain

**Correção Sugerida:**
```dart
// Estrutura recomendada:
lib/
  core/
    errors/
    usecases/
  features/
    auth/
      data/
        datasources/
          auth_remote_datasource.dart
        repositories/
          auth_repository_impl.dart
      domain/
        entities/
          user.dart
        repositories/
          auth_repository.dart
        usecases/
          sign_in_usecase.dart
      presentation/
        bloc/
        screens/
        widgets/

// Exemplo de Repository Pattern:
abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, void>> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  AuthRepositoryImpl(this.remoteDataSource);
  
  @override
  Future<Either<Failure, User>> signIn(String email, String password) async {
    try {
      final user = await remoteDataSource.signIn(email, password);
      return Right(user);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

---

### 9. **Singleton Anti-Pattern**
**Localização:** `lib/features/gamification/services/gamification_service.dart` (linha 28)
**Severidade:** 🟡 MÉDIA

**Problema:**
```dart
static final GamificationService _instance = GamificationService._internal();
factory GamificationService() => _instance;
```

**Impacto:**
- Dificulta testes unitários
- Acoplamento forte
- Estado global mutável

**Correção Sugerida:**
```dart
// Usar Dependency Injection
class GamificationService {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;
  
  GamificationService({
    required SupabaseClient supabase,
    required SharedPreferences prefs,
  }) : _supabase = supabase, _prefs = prefs;
}

// No main.dart, usar GetIt ou Provider
void main() async {
  final getIt = GetIt.instance;
  
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);
  getIt.registerSingletonAsync<SharedPreferences>(
    () => SharedPreferences.getInstance()
  );
  getIt.registerLazySingleton<GamificationService>(
    () => GamificationService(
      supabase: getIt<SupabaseClient>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  
  runApp(MyApp());
}
```

---

### 10. **Acoplamento Direto ao Supabase**
**Localização:** Múltiplos arquivos
**Severidade:** 🟡 MÉDIA

**Problema:**
```dart
final service = MissionsService(Supabase.instance.client);
```

**Impacto:**
- Impossível trocar backend sem reescrever código
- Dificulta testes
- Viola princípio de inversão de dependência

**Correção Sugerida:**
```dart
// Criar abstrações
abstract class DatabaseClient {
  Future<List<Map<String, dynamic>>> query(String table);
  Future<void> insert(String table, Map<String, dynamic> data);
  Future<void> update(String table, Map<String, dynamic> data);
}

class SupabaseDatabaseClient implements DatabaseClient {
  final SupabaseClient _client;
  SupabaseDatabaseClient(this._client);
  
  @override
  Future<List<Map<String, dynamic>>> query(String table) async {
    return await _client.from(table).select();
  }
}

// Services usam abstração
class MissionsService {
  final DatabaseClient _db;
  MissionsService(this._db);
}
```

---

## 🟢 PRIORIDADE MÉDIA: Bugs e Erros Lógicos

### 11. **Race Condition em Streak**
**Localização:** `lib/features/gamification/services/gamification_service.dart` (linha 200)
**Severidade:** 🟡 MÉDIA

**Problema:**
```dart
final firstReadOfDay = !(await _hasAnyDevotionalReadToday(user.id, todayUtc));
// ... código assíncrono ...
await GamificationService.markDevotionalAsRead(devotionalId, firstReadOfDay: firstReadOfDay);
```

**Impacto:**
- Se usuário ler 2 devocionais simultaneamente, ambos podem ser "primeira leitura"
- XP duplicado

**Correção Sugerida:**
```dart
// Usar transação ou lock otimista
Future<bool> markAsRead(int devotionalId) async {
  return await _db.transaction((txn) async {
    final alreadyRead = await _hasReadToday(devotionalId, user.id, today);
    if (alreadyRead) return false;
    
    final firstRead = !(await _hasAnyDevotionalReadToday(user.id, today));
    
    await txn.insert('read_devotionals', {...});
    await _awardXp(firstRead: firstRead);
    
    return true;
  });
}
```

---

### 12. **Memory Leak Potencial**
**Localização:** `lib/features/home/screens/home_screen.dart` (linha 35)
**Severidade:** 🟡 MÉDIA

**Problema:**
```dart
GamificationService.events.listen((event) async {
  // Listener nunca é cancelado
});
```

**Impacto:**
- Listener continua ativo após dispose
- Vazamento de memória
- Callbacks em widget destruído

**Correção Sugerida:**
```dart
class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _eventsSubscription;
  
  @override
  void initState() {
    super.initState();
    _eventsSubscription = GamificationService.events.listen((event) async {
      if (!mounted) return;
      // ...
    });
  }
  
  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
```

---

### 13. **Null Safety Inadequado**
**Localização:** `lib/features/quotes/screens/quote_screen.dart` (linha 193)
**Severidade:** 🟢 BAIXA

**Problema:**
```dart
final RenderRepaintBoundary boundary =
    _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
```

**Impacto:**
- Pode crashar se context for null
- Uso de `!` força unwrap

**Correção Sugerida:**
```dart
Future<ui.Image?> _captureScreen() async {
  final context = _globalKey.currentContext;
  if (context == null) {
    debugPrint('Context is null, cannot capture screen');
    return null;
  }
  
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    debugPrint('RenderObject is not RenderRepaintBoundary');
    return null;
  }
  
  return await renderObject.toImage(pixelRatio: 3.0);
}
```

---

## 🔵 PRIORIDADE BAIXA: Hardcoding e Configuração

### 14. **Valores Hardcoded**
**Localização:** Múltiplos arquivos
**Severidade:** 🟢 BAIXA

**Exemplos:**
```dart
// quote_screen.dart (linha 67)
backgroundColor: Color(0xFF005954)

// home_screen.dart (linha 245)
'Desejamos que tenha um bom dia'

// gamification_service.dart (linha 150)
xpAmount: 8
```

**Correção Sugerida:**
```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  // Cores
  static const primaryColor = Color(0xFF005954);
  static const complementaryColor = Color(0xFF338b85);
  
  // XP Values
  static const xpDevotionalRead = 8;
  static const xpDailyBonus = 5;
  static const xpStreak3Days = 15;
  
  // Mensagens
  static const greetingMorning = 'Bom dia';
  static const greetingAfternoon = 'Boa tarde';
  static const greetingEvening = 'Boa noite';
}

// Uso:
backgroundColor: AppConstants.primaryColor
xpAmount: AppConstants.xpDevotionalRead
```

---

### 15. **URLs Hardcoded**
**Localização:** `lib/features/quotes/screens/quote_screen.dart` (linha 36-43)
**Severidade:** 🟢 BAIXA

**Problema:**
```dart
final images = [
  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
  // ...
];
```

**Correção Sugerida:**
```dart
// lib/core/constants/image_constants.dart
class ImageConstants {
  static const unsplashImages = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
    // ...
  ];
}

// Ou melhor: carregar de arquivo JSON
// assets/config/images.json
{
  "quote_backgrounds": [
    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop"
  ]
}
```

---

## 🎨 PRIORIDADE BAIXA: Boas Práticas

### 16. **Funções Muito Longas**
**Localização:** `lib/features/home/screens/home_screen.dart` (linha 200-400)
**Severidade:** 🟢 BAIXA

**Problema:**
- Método `_buildProgressCard()` com 200+ linhas
- Dificulta leitura e manutenção

**Correção Sugerida:**
```dart
Widget _buildProgressCard() {
  return Card(
    child: Column(
      children: [
        _buildLevelSection(),
        _buildProgressBar(),
        _buildStatsSection(),
        _buildMissionsSection(),
        _buildReadingPlansSection(),
      ],
    ),
  );
}

Widget _buildLevelSection() { /* ... */ }
Widget _buildProgressBar() { /* ... */ }
// etc
```

---

### 17. **Falta de Documentação**
**Localização:** Todo o projeto
**Severidade:** 🟢 BAIXA

**Problema:**
- Métodos complexos sem documentação
- Parâmetros sem descrição
- Falta de exemplos de uso

**Correção Sugerida:**
```dart
/// Marca um devocional como lido e atualiza gamificação.
///
/// Este método:
/// 1. Verifica se já foi lido hoje
/// 2. Insere registro em read_devotionals
/// 3. Atualiza XP e streak do usuário
/// 4. Completa missões relacionadas
///
/// Parâmetros:
/// - [devotionalId]: ID do devocional a ser marcado
///
/// Retorna:
/// - `true` se marcado com sucesso
/// - `false` se já foi lido hoje ou erro
///
/// Exemplo:
/// ```dart
/// final success = await service.markAsRead(123);
/// if (success) {
///   print('Devocional marcado!');
/// }
/// ```
Future<bool> markAsRead(int devotionalId) async {
  // ...
}
```

---

### 18. **Magic Numbers**
**Localização:** Múltiplos arquivos
**Severidade:** 🟢 BAIXA

**Exemplos:**
```dart
// gamification_service.dart
if (password.length < 6) // Por que 6?
await Future.delayed(const Duration(milliseconds: 350)); // Por que 350?
final levelRequirements = [0, 150, 400, 750, 1200]; // De onde vieram?
```

**Correção Sugerida:**
```dart
class ValidationConstants {
  static const minPasswordLength = 6; // Requisito mínimo de segurança
  static const imageLoadDelay = Duration(milliseconds: 350); // Tempo para renderização
}

class LevelConstants {
  static const requirements = [
    0,    // Nível 1
    150,  // Nível 2
    400,  // Nível 3
    750,  // Nível 4
    1200, // Nível 5
  ];
}
```

---

### 19. **Falta de Testes**
**Localização:** Projeto inteiro
**Severidade:** 🟢 BAIXA

**Problema:**
- Nenhum teste unitário
- Nenhum teste de integração
- Nenhum teste de widget

**Correção Sugerida:**
```dart
// test/features/auth/services/auth_service_test.dart
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockSupabase;
    
    setUp(() {
      mockSupabase = MockSupabaseClient();
      authService = AuthService(mockSupabase);
    });
    
    test('signIn deve retornar usuário quando credenciais válidas', () async {
      // Arrange
      when(() => mockSupabase.auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => AuthResponse(user: mockUser));
      
      // Act
      await authService.signInWithEmail(
        email: 'test@test.com',
        password: 'password123',
      );
      
      // Assert
      verify(() => mockSupabase.auth.signInWithPassword(
        email: 'test@test.com',
        password: 'password123',
      )).called(1);
    });
  });
}
```

---

### 20. **Falta de Internacionalização**
**Localização:** Todo o projeto
**Severidade:** 🟢 BAIXA

**Problema:**
- Todas as strings hardcoded em português
- Impossível suportar outros idiomas

**Correção Sugerida:**
```dart
// pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.0

// lib/l10n/app_pt.arb
{
  "welcomeBack": "Bem-vindo de volta",
  "email": "Email",
  "password": "Senha",
  "@welcomeBack": {
    "description": "Mensagem de boas-vindas na tela de login"
  }
}

// Uso:
Text(AppLocalizations.of(context)!.welcomeBack)
```

---

## 📊 Resumo Estatístico

| Categoria | Crítica | Alta | Média | Baixa | Total |
|-----------|---------|------|-------|-------|-------|
| Segurança | 1 | 3 | 2 | 0 | 6 |
| Modularidade | 0 | 0 | 4 | 0 | 4 |
| Bugs | 0 | 0 | 3 | 1 | 4 |
| Hardcoding | 0 | 0 | 0 | 2 | 2 |
| Boas Práticas | 0 | 0 | 0 | 4 | 4 |
| **TOTAL** | **1** | **3** | **9** | **7** | **20** |

---

## 🎯 Recomendações Prioritárias

### Curto Prazo (1-2 semanas)
1. ✅ Corrigir validação de email e senha
2. ✅ Implementar logging centralizado
3. ✅ Adicionar validação de credenciais Supabase
4. ✅ Corrigir memory leaks (cancelar subscriptions)

### Médio Prazo (1 mês)
5. ✅ Refatorar HomeScreen em widgets menores
6. ✅ Implementar Repository Pattern
7. ✅ Adicionar testes unitários críticos
8. ✅ Criar constants centralizados

### Longo Prazo (2-3 meses)
9. ✅ Implementar Clean Architecture completa
10. ✅ Adicionar internacionalização
11. ✅ Implementar CI/CD com testes automatizados
12. ✅ Adicionar monitoramento de erros (Sentry/Firebase)

---

## 📚 Recursos Recomendados

- **Clean Architecture:** https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Flutter Best Practices:** https://docs.flutter.dev/development/data-and-backend/state-mgmt/options
- **OWASP Mobile Security:** https://owasp.org/www-project-mobile-security-testing-guide/
- **Dart Style Guide:** https://dart.dev/guides/language/effective-dart

---

**Gerado automaticamente por Amazon Q Developer**
