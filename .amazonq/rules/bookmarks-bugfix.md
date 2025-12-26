# Regras: Correção de Bugs - Sistema de Bookmarks

## 🎯 Objetivo
Corrigir 3 bugs críticos no sistema de bookmarks que causam erros 400 e crashes.

## 📋 Bugs Identificados

### Bug 1: Query `ilike` Malformada
- **Arquivo**: `verses_screen.dart`
- **Linhas**: 145-155
- **Ação**: Remover fallback com `ilike('book_name', widget.bookName)`
- **Substituir por**: Log de erro e retornar `{}`

### Bug 2: `onConflict` Incorreto
- **Arquivo**: `weekly_challenges_service.dart`
- **Linha**: 52
- **Ação**: Remover parâmetro `onConflict: 'user_profile_id,challenge_id'`
- **Motivo**: Supabase detecta UNIQUE constraint automaticamente

### Bug 3: Context Após Async
- **Arquivo**: `verses_screen.dart`
- **Locais**: 4 callbacks (toggleHighlight, setHighlight, removeHighlight, upsertNote)
- **Ação**: Capturar `final messenger = ScaffoldMessenger.of(context)` ANTES de qualquer `await`
- **Padrão**:
```dart
onPressed: () async {
  final messenger = ScaffoldMessenger.of(context);  // SEMPRE PRIMEIRO
  Navigator.pop(context);
  // ... operações async ...
  if (!mounted) return;
  messenger.showSnackBar(...);  // Usar messenger, não context
},
```

## ✅ Checklist de Implementação

### Fase 1: Correções (15min)
- [ ] Bug 1: Remover `ilike` fallback
- [ ] Bug 2: Remover `onConflict`
- [ ] Bug 3: Capturar messenger (4 locais)

### Fase 2: Testes (10min)
- [ ] Testar highlight de versículo
- [ ] Testar remoção de highlight
- [ ] Testar adição de nota
- [ ] Verificar logs: sem erros 400
- [ ] Verificar: SnackBars aparecem corretamente

### Fase 3: Validação (5min)
- [ ] Todos os testes passaram
- [ ] Nenhum erro no console
- [ ] UX fluida sem crashes

## 🚫 Regras de Implementação

### NUNCA
- ❌ Usar `ScaffoldMessenger.of(context)` após `await`
- ❌ Usar `ilike` sem wildcards `%`
- ❌ Passar `onConflict` como string de colunas

### SEMPRE
- ✅ Capturar `ScaffoldMessenger` ANTES de async
- ✅ Verificar `mounted` antes de `setState`
- ✅ Logar erros com `LogService.error()`
- ✅ Deixar Supabase inferir constraints em `upsert()`

## 📊 Critérios de Sucesso
- Zero erros 400 no console
- Zero crashes por widget disposed
- Bookmarks salvam/removem corretamente
- SnackBars aparecem sem erros
