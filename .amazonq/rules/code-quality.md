# Regras de Qualidade de Código - BibliApp

## Nomenclatura

### Classes
- PascalCase: `UserProfile`, `AuthService`
- Sufixos descritivos: `*Screen`, `*Service`, `*Repository`, `*Widget`
- Nomes claros e específicos

### Variáveis e Métodos
- camelCase: `userName`, `getUserProfile()`
- Booleanos: prefixo `is`, `has`, `should`
- Privados: prefixo `_`

### Constantes
- lowerCamelCase para const: `primaryColor`
- UPPER_SNAKE_CASE para static const: `MAX_RETRY_COUNT`

### Arquivos
- snake_case: `user_profile.dart`, `auth_service.dart`
- Mesmo nome da classe principal

## Funções

### Tamanho Máximo
- 50 linhas por função
- Se maior: extrair em funções auxiliares
- Uma responsabilidade por função

### Parâmetros
- Máximo 4 parâmetros posicionais
- Usar named parameters se > 2
- Usar classes para múltiplos parâmetros relacionados

```dart
// ❌ Evitar
void createUser(String name, String email, int age, String city, String country);

// ✅ Preferir
void createUser({
  required String name,
  required String email,
  required int age,
  String? city,
  String? country,
});

// ✅ Ou melhor ainda
void createUser(UserData data);
```

## Documentação

### Obrigatório Documentar
- Classes públicas
- Métodos públicos complexos
- Parâmetros não óbvios
- Retornos não óbvios

### Formato
```dart
/// Breve descrição em uma linha.
///
/// Descrição detalhada em múltiplas linhas
/// explicando o comportamento.
///
/// Parâmetros:
/// - [userId]: ID do usuário
/// - [includeDeleted]: Se deve incluir registros deletados
///
/// Retorna:
/// Lista de [UserProfile] ou lista vazia se nenhum encontrado.
///
/// Lança:
/// - [AuthException] se usuário não autenticado
/// - [NetworkException] se sem conexão
///
/// Exemplo:
/// ```dart
/// final profiles = await service.getProfiles(
///   userId: '123',
///   includeDeleted: false,
/// );
/// ```
Future<List<UserProfile>> getProfiles({
  required String userId,
  bool includeDeleted = false,
}) async {
  // ...
}
```

## Constantes

### Centralização
- NUNCA valores mágicos no código
- Criar arquivos de constantes por categoria
- Usar classes estáticas

```dart
// lib/core/constants/app_colors.dart
class AppColors {
  static const primary = Color(0xFF005954);
  static const complementary = Color(0xFF338b85);
  static const background = Color(0xFFFFFFFF);
}

// lib/core/constants/app_dimensions.dart
class AppDimensions {
  static const paddingSmall = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge = 24.0;
  static const borderRadius = 12.0;
}

// lib/core/constants/xp_values.dart
class XpValues {
  static const devotionalRead = 8;
  static const dailyBonus = 5;
  static const streak3Days = 15;
  static const streak7Days = 35;
}
```

## Null Safety

### Regras
- SEMPRE usar null safety
- Evitar `!` (force unwrap)
- Preferir `?.` e `??`
- Validar antes de usar

```dart
// ❌ Evitar
final name = user!.name!;

// ✅ Preferir
final name = user?.name ?? 'Usuário';

// ✅ Ou validar
if (user == null) {
  throw ArgumentError('User cannot be null');
}
final name = user.name;
```

## Tratamento de Erros

### Try-Catch
- NUNCA catch silencioso
- Capturar erros específicos
- Logar sempre
- Mostrar feedback ao usuário

```dart
// ❌ Evitar
try {
  await operation();
} catch (_) {}

// ✅ Preferir
try {
  await operation();
} on NetworkException catch (e, stack) {
  LogService.logError('Operation failed', e, stack);
  _showErrorMessage('Sem conexão com internet');
} on AuthException catch (e, stack) {
  LogService.logError('Auth failed', e, stack);
  _showErrorMessage('Sessão expirada');
} catch (e, stack) {
  LogService.logError('Unexpected error', e, stack);
  _showErrorMessage('Erro inesperado');
}
```

## Performance

### Otimizações
- Usar `const` constructors sempre que possível
- Evitar rebuilds desnecessários
- Usar `ListView.builder` para listas longas
- Cachear dados quando apropriado

```dart
// ✅ Usar const
const Text('Hello');
const SizedBox(height: 16);
const Icon(Icons.home);

// ✅ Evitar rebuilds
class MyWidget extends StatelessWidget {
  final String title;
  const MyWidget({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
```

## Imports

### Organização
1. Dart SDK
2. Flutter SDK
3. Packages externos
4. Imports locais

```dart
// Dart
import 'dart:async';
import 'dart:convert';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Packages
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local
import 'package:bibli_app/core/constants/app_colors.dart';
import 'package:bibli_app/features/auth/services/auth_service.dart';
```

### Limpeza
- Remover imports não utilizados
- Usar `flutter pub run import_sorter:main`
- Configurar IDE para organizar automaticamente

## Comentários

### Quando Comentar
- Lógica complexa não óbvia
- Workarounds temporários (com TODO)
- Decisões de design importantes
- Algoritmos complexos

### Quando NÃO Comentar
- Código auto-explicativo
- Repetir o que o código já diz
- Comentários obsoletos

```dart
// ❌ Comentário inútil
// Incrementa o contador
counter++;

// ✅ Comentário útil
// Workaround: API retorna data em formato incorreto (YYYY-DD-MM)
// TODO: Remover quando API for corrigida (ticket #123)
final date = _parseIncorrectDateFormat(apiDate);
```

## Testes

### Cobertura Mínima
- Services: 80%
- UseCases: 90%
- Repositories: 70%
- Widgets críticos: 60%

### Estrutura
```dart
void main() {
  group('AuthService', () {
    late AuthService service;
    late MockSupabaseClient mockClient;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      service = AuthService(mockClient);
    });
    
    tearDown(() {
      // Cleanup
    });
    
    test('signIn deve retornar usuário quando credenciais válidas', () async {
      // Arrange
      when(() => mockClient.auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockAuthResponse);
      
      // Act
      await service.signIn(email: 'test@test.com', password: 'pass123');
      
      // Assert
      verify(() => mockClient.auth.signInWithPassword(
        email: 'test@test.com',
        password: 'pass123',
      )).called(1);
    });
  });
}
```

## Code Review Checklist

Antes de commitar, verificar:
- [ ] Sem valores hardcoded
- [ ] Sem magic numbers
- [ ] Tratamento de erros adequado
- [ ] Null safety correto
- [ ] Documentação presente
- [ ] Testes escritos
- [ ] Imports organizados
- [ ] Sem warnings do analyzer
- [ ] Formatação correta (dart format)
