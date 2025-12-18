# Regras de Arquitetura - BibliApp

## Estrutura de Pastas

### Padrão Obrigatório
```
lib/
  core/
    constants/      # Valores constantes
    errors/         # Classes de erro customizadas
    usecases/       # Use cases base
    utils/          # Utilitários
  features/
    [feature_name]/
      data/
        datasources/  # Acesso a APIs/DB
        models/       # DTOs e modelos de dados
        repositories/ # Implementação de repositories
      domain/
        entities/     # Entidades de negócio
        repositories/ # Interfaces de repositories
        usecases/     # Casos de uso
      presentation/
        bloc/         # Gerenciamento de estado
        screens/      # Telas
        widgets/      # Widgets reutilizáveis
```

## Separação de Responsabilidades

### Screens (Presentation)
- APENAS UI e navegação
- NUNCA lógica de negócio
- NUNCA acesso direto a database
- Máximo 300 linhas por arquivo
- Extrair widgets se > 200 linhas

### Services (Data Layer)
- Acesso a APIs e database
- Transformação de dados (DTO ↔ Entity)
- NUNCA lógica de negócio complexa
- NUNCA acesso direto a Supabase.instance

### UseCases (Domain Layer)
- Lógica de negócio pura
- Orquestração de repositories
- Validações de regras de negócio
- Independente de framework

## Dependency Injection

### Proibido
```dart
// ❌ NUNCA fazer isso
final service = MissionsService(Supabase.instance.client);
```

### Correto
```dart
// ✅ Usar DI
class MissionsService {
  final DatabaseClient _db;
  MissionsService(this._db);
}

// No main.dart
getIt.registerLazySingleton<MissionsService>(
  () => MissionsService(getIt<DatabaseClient>()),
);
```

## Widgets

### Tamanho Máximo
- StatelessWidget: 150 linhas
- StatefulWidget: 300 linhas
- Se maior: extrair em widgets menores

### Composição
- Preferir composição sobre herança
- Criar widgets reutilizáveis
- Usar const constructors quando possível

### Exemplo
```dart
// ❌ Evitar
Widget build(BuildContext context) {
  return Column(
    children: [
      // 200 linhas de código aqui
    ],
  );
}

// ✅ Preferir
Widget build(BuildContext context) {
  return Column(
    children: [
      _HeaderSection(),
      _ContentSection(),
      _FooterSection(),
    ],
  );
}
```

## Estado

### Gerenciamento
- Usar Provider, Bloc ou Riverpod
- NUNCA setState para estado global
- Separar estado local de global

### Streams e Subscriptions
- SEMPRE cancelar em dispose()
- Verificar `mounted` antes de setState
- Usar StreamBuilder quando possível

```dart
class _MyScreenState extends State<MyScreen> {
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {
      if (!mounted) return;
      setState(() { /* ... */ });
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## Abstrações

### Interfaces
- Criar interfaces para services externos
- Facilitar testes e troca de implementação
- Seguir Dependency Inversion Principle

```dart
// ✅ Correto
abstract class DatabaseClient {
  Future<List<Map<String, dynamic>>> query(String table);
}

class SupabaseDatabaseClient implements DatabaseClient {
  final SupabaseClient _client;
  // ...
}
```

## Singleton

### Evitar
- NUNCA usar singleton para services
- Usar DI container (GetIt, Provider)
- Facilita testes e manutenção

```dart
// ❌ Evitar
class MyService {
  static final instance = MyService._();
  MyService._();
}

// ✅ Preferir
class MyService {
  final Dependency _dep;
  MyService(this._dep);
}
```

## Modularização

### Princípios
- Alta coesão, baixo acoplamento
- Features independentes
- Reutilização de código
- Fácil de testar

### Exemplo de Feature Independente
```dart
// feature/auth pode ser extraído como package
auth/
  lib/
    auth.dart  # Exports públicos
    src/       # Implementação privada
  test/
  pubspec.yaml
```
