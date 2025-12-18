# Regras de Segurança - BibliApp

## Validação de Entrada

### Email
- SEMPRE usar regex completo: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- NUNCA aceitar apenas `contains('@')`
- Sanitizar antes de enviar ao backend

### Senha
- Mínimo 8 caracteres
- Exigir: maiúscula, minúscula, número, caractere especial
- Validar força antes de aceitar

### IDs e Parâmetros
- Validar tipo e formato antes de queries
- User ID: UUID formato `^[a-f0-9-]{36}$`
- IDs numéricos: verificar `is int` e `> 0`

## Credenciais

### Supabase
- NUNCA commitar credenciais
- SEMPRE usar `--dart-define` em build
- Validar formato e HTTPS em runtime
- Lançar erro se ausente, não usar default vazio

### Armazenamento
- Dados sensíveis: usar `flutter_secure_storage`
- NUNCA usar SharedPreferences para tokens/senhas
- Criptografar cache local se contiver PII

## Tratamento de Erros

### Logging
- NUNCA usar `catch (_) {}` silencioso
- SEMPRE logar contexto, erro e stack trace
- Em produção: enviar para Sentry/Firebase Crashlytics
- Mostrar mensagem amigável ao usuário

### Exemplo Correto
```dart
try {
  await operation();
} catch (e, stack) {
  LogService.logError('ClassName.methodName', e, stack);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao processar operação')),
    );
  }
}
```

## SQL/Database

### Queries
- SEMPRE validar tipos antes de `.eq()`
- NUNCA concatenar strings em queries
- Usar prepared statements (Supabase já faz)
- Validar IDs antes de passar para query

### Transações
- Operações críticas: usar transações
- Evitar race conditions em operações concorrentes
- Implementar retry logic para falhas temporárias

## Autenticação

### Tokens
- NUNCA armazenar em SharedPreferences
- Usar secure storage ou deixar Supabase gerenciar
- Validar expiração antes de usar
- Implementar refresh automático

### Sessões
- Verificar `currentUser != null` antes de operações
- Limpar cache ao fazer logout
- Redirecionar para login se sessão expirar
