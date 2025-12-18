# 📋 Próximos Passos - BibliApp

## ✅ JÁ IMPLEMENTADO (94%)

### 1️⃣ Validação de Email ✅
- ✅ Arquivo criado: `lib/core/validators/validators.dart` (EmailValidator)
- ✅ Integrado em: `signup_screen.dart`, `login_screen.dart`

### 2️⃣ Validação de Senha ✅
- ✅ Arquivo criado: `lib/core/validators/validators.dart` (PasswordValidator)
- ✅ Integrado em: `signup_screen.dart`

### 3️⃣ Logging Centralizado ✅
- ✅ Arquivo criado: `lib/core/services/log_service.dart`
- ✅ Integrado em: auth_service, devotional_service, quote_screen, devotional_screen, missions_screen, home_screen
- ⚠️ **PENDENTE**: Substituir prints restantes em outros arquivos

### 4️⃣ Constantes Centralizadas ✅
- ✅ Arquivo criado: `lib/core/constants/app_constants.dart`
  - AppColors (primary, complementary)
  - XpValues (devotionalRead, dailyBonus, streaks)
  - AppDimensions (padding, borderRadius)
- ✅ Integrado em: 8+ arquivos
- ⚠️ **PENDENTE**: Substituir magic numbers restantes

### 5️⃣ Memory Leak Corrigido ✅
- ✅ home_screen.dart: StreamSubscription cancelada em dispose()

### 6️⃣ Credenciais Supabase ✅
- ✅ Dotenv implementado: `.env` + `flutter_dotenv`
- ✅ Config validado: `lib/core/config.dart` com validação HTTPS

---

## 🎯 PRÓXIMOS PASSOS CLAROS

### PASSO 1: Completar Refatoração (6% restante)
**Tempo estimado: 2-3 horas**

#### 1.1 Substituir prints restantes por LogService
Arquivos a verificar:
```bash
cd bibli_app
grep -r "print(" lib/ --exclude-dir={build,test}
```

Substituir padrão:
```dart
// De:
print('Mensagem');

// Para:
LogService.info('Mensagem', 'NomeDoArquivo');
```

#### 1.2 Extrair magic numbers restantes
Buscar números hardcoded:
```bash
grep -rE "\b[0-9]{2,}\b" lib/ --include="*.dart" | grep -v "const\|static\|//"
```

Adicionar em `app_constants.dart` conforme necessário.

#### 1.3 Criar AppStrings (do guia)
```dart
// lib/core/constants/app_strings.dart
class AppStrings {
  static const errorGeneric = 'Ocorreu um erro inesperado';
  static const errorNetwork = 'Sem conexão com a internet';
  static const errorAuth = 'Sessão expirada. Faça login novamente';
  // ... resto das strings
}
```

**Checklist:**
- [ ] Substituir prints restantes
- [ ] Extrair magic numbers
- [ ] Criar app_strings.dart
- [ ] Substituir strings hardcoded

---

### PASSO 2: Testes Automatizados
**Tempo estimado: 1 dia**

#### 2.1 Criar estrutura de testes
```bash
cd bibli_app
mkdir -p test/unit test/widget
```

#### 2.2 Testes unitários (validators)
```dart
// test/unit/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/validators/validators.dart';

void main() {
  group('EmailValidator', () {
    test('deve aceitar email válido', () {
      expect(EmailValidator.validate('test@example.com'), null);
    });
    
    test('deve rejeitar email sem @', () {
      expect(EmailValidator.validate('invalid'), isNotNull);
    });
    
    test('deve rejeitar email vazio', () {
      expect(EmailValidator.validate(''), isNotNull);
    });
  });
  
  group('PasswordValidator', () {
    test('deve aceitar senha forte', () {
      expect(PasswordValidator.validate('Senha@123'), null);
    });
    
    test('deve rejeitar senha curta', () {
      expect(PasswordValidator.validate('123'), isNotNull);
    });
    
    test('deve rejeitar senha sem maiúscula', () {
      expect(PasswordValidator.validate('senha@123'), isNotNull);
    });
  });
}
```

#### 2.3 Testes de services (com mocks)
```yaml
# pubspec.yaml - adicionar
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

```dart
// test/unit/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthService', () {
    test('signIn deve retornar usuário quando credenciais válidas', () async {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

#### 2.4 Widget tests (telas críticas)
```dart
// test/widget/login_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('LoginScreen deve mostrar campos de email e senha', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });
}
```

**Checklist:**
- [ ] Criar estrutura test/
- [ ] Testes validators (100% cobertura)
- [ ] Testes services (80% cobertura)
- [ ] Widget tests (login, signup, home)
- [ ] Rodar: `flutter test`

---

### PASSO 3: Performance
**Tempo estimado: 4-6 horas**

#### 3.1 Adicionar cached_network_image
```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.3.0
```

```dart
// Substituir Image.network por:
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

Arquivos a atualizar:
- `quote_screen.dart` (imagens Unsplash)
- Qualquer outro com Image.network

#### 3.2 Adicionar splash screen
```yaml
# pubspec.yaml
dependencies:
  flutter_native_splash: ^2.3.0
```

```yaml
# pubspec.yaml - adicionar configuração
flutter_native_splash:
  color: "#005954"
  image: assets/images/logo.png
  android: true
  ios: false
```

```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

#### 3.3 Adicionar loading states
Criar widget reutilizável:
```dart
// lib/core/widgets/loading_indicator.dart
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }
}
```

Usar em todas as telas com FutureBuilder/StreamBuilder.

**Checklist:**
- [ ] Adicionar cached_network_image
- [ ] Substituir Image.network
- [ ] Configurar splash screen
- [ ] Criar LoadingIndicator widget
- [ ] Adicionar loading em todas as telas

---

### PASSO 4: CI/CD
**Tempo estimado: 3-4 horas**

#### 4.1 Criar GitHub Actions
```yaml
# .github/workflows/flutter.yml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    
    - name: Install dependencies
      run: |
        cd bibli_app
        flutter pub get
    
    - name: Analyze code
      run: |
        cd bibli_app
        flutter analyze
    
    - name: Run tests
      run: |
        cd bibli_app
        flutter test
    
    - name: Build APK
      run: |
        cd bibli_app
        flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release.apk
        path: bibli_app/build/app/outputs/flutter-apk/app-release.apk
```

**Checklist:**
- [ ] Criar .github/workflows/flutter.yml
- [ ] Testar workflow localmente
- [ ] Fazer commit e verificar Actions
- [ ] Configurar secrets (SUPABASE_URL, SUPABASE_ANON_KEY)

---

### PASSO 5: Monitoramento (Sentry)
**Tempo estimado: 2-3 horas**

#### 5.1 Adicionar Sentry
```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0
```

#### 5.2 Configurar Sentry
```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://seu-dsn@sentry.io/projeto';
      options.tracesSampleRate = 1.0;
      options.environment = kReleaseMode ? 'production' : 'development';
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

#### 5.3 Integrar com LogService
```dart
// lib/core/services/log_service.dart
static void error(...) {
  _log(LogLevel.error, message, context, error, stackTrace);
  
  if (kReleaseMode && error != null) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
```

**Checklist:**
- [ ] Criar conta Sentry (sentry.io)
- [ ] Adicionar sentry_flutter
- [ ] Configurar DSN
- [ ] Integrar com LogService
- [ ] Testar envio de erros

---

## 📊 RESUMO DE PRIORIDADES

### 🔴 Alta Prioridade (Fazer Agora)
1. **PASSO 1**: Completar refatoração (6% restante) - 2-3h
2. **PASSO 2**: Testes automatizados - 1 dia
3. **PASSO 3**: Performance - 4-6h

### 🟡 Média Prioridade (Próxima Sprint)
4. **PASSO 4**: CI/CD - 3-4h
5. **PASSO 5**: Monitoramento - 2-3h

### 🟢 Baixa Prioridade (Futuro)
- Dependency Injection (get_it)
- Offline first (Hive)
- Internacionalização (i18n)
- Supabase Realtime
- Deep Linking

---

## 🎯 PLANO DE AÇÃO SEMANAL

### Semana 1
- **Dia 1-2**: PASSO 1 (Completar refatoração)
- **Dia 3-5**: PASSO 2 (Testes)

### Semana 2
- **Dia 1-2**: PASSO 3 (Performance)
- **Dia 3**: PASSO 4 (CI/CD)
- **Dia 4-5**: PASSO 5 (Monitoramento)

---

## ✅ CHECKLIST GERAL

### Refatoração
- [ ] Substituir prints restantes
- [ ] Extrair magic numbers
- [ ] Criar app_strings.dart
- [ ] Substituir strings hardcoded

### Testes
- [ ] Estrutura test/
- [ ] Validators tests
- [ ] Services tests
- [ ] Widget tests
- [ ] Cobertura > 80%

### Performance
- [ ] cached_network_image
- [ ] Splash screen
- [ ] Loading states

### DevOps
- [ ] GitHub Actions
- [ ] Sentry configurado
- [ ] Build automático

---

## 🚀 COMEÇAR AGORA

**Comando para começar PASSO 1:**
```bash
cd bibli_app

# 1. Buscar prints restantes
grep -r "print(" lib/ --exclude-dir={build,test}

# 2. Buscar magic numbers
grep -rE "\b[0-9]{2,}\b" lib/ --include="*.dart" | grep -v "const\|static\|//"

# 3. Criar app_strings.dart
# (código fornecido acima)
```

**Quer que eu implemente o PASSO 1 agora?**
