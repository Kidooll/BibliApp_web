# Análise de Bugs: Sistema de Bookmarks

**Data**: 2024-12-19  
**Status**: Análise Comparativa Completa

---

## 🔴 Problemas Identificados

### 1. **Erro 400: Query Malformada em `_loadVerseIds()`**

#### Problema
```
GET /rest/v1/verses?select=id%2Cverse_number&chapter_number=eq.2&book_name=ilike.Levítico
```

**Causa Raiz**: Filtro `ilike` aplicado incorretamente na coluna `book_name`.

#### Código Problemático (verses_screen.dart:145-155)
```dart
fallbackRows = await Supabase.instance.client
    .from('verses')
    .select('id, verse_number')
    .eq('chapter_number', chapter)
    .ilike('book_name', widget.bookName);  // ❌ ERRO: ilike sem % wildcards
```

#### Código de Referência (verse_actions_modal.dart)
```dart
// ✅ Usa RPC function ao invés de queries complexas
final response = await _supabase.rpc('get_highlights_for_verse', params: {
  'p_verse_id': widget.verseId,
  'p_user_profile_id': user.id
}).maybeSingle();
```

**Diferença Crítica**:
- ❌ **Problemático**: Usa `ilike` sem wildcards (`%`) → Supabase rejeita
- ✅ **Referência**: Usa RPC functions para queries complexas

---

### 2. **Erro 400: POST com `on_conflict` Malformado**

#### Problema
```
POST /rest/v1/user_challenge_progress?on_conflict=user_profile_id%2Cchallenge_id
```

**Causa Raiz**: Parâmetro `onConflict` passado como string simples ao invés de constraint name.

#### Código Problemático (weekly_challenges_service.dart:52)
```dart
await _supabase.from('user_challenge_progress').upsert({
  'user_profile_id': user.id,
  'challenge_id': challengeId,
  'current_progress': 0,
  'is_completed': false,
}, onConflict: 'user_profile_id,challenge_id');  // ❌ ERRO: formato incorreto
```

#### Solução Correta
```dart
// ✅ Usar constraint name ou deixar Supabase inferir
await _supabase.from('user_challenge_progress').upsert({
  'user_profile_id': user.id,
  'challenge_id': challengeId,
  'current_progress': 0,
  'is_completed': false,
});  // Supabase usa UNIQUE constraint automaticamente
```

**Diferença Crítica**:
- ❌ **Problemático**: `onConflict: 'user_profile_id,challenge_id'` (string)
- ✅ **Correto**: Omitir parâmetro ou usar nome da constraint

---

### 3. **Erro: Widget Desativado (verses_screen.dart:400)**

#### Problema
```dart
ScaffoldMessenger.of(context).showSnackBar(...)  // ❌ Contexto inválido após async
```

**Causa Raiz**: Acesso a `context` após operação assíncrona sem verificar `mounted`.

#### Código Problemático (verses_screen.dart:348-360)
```dart
onPressed: () async {
  Navigator.pop(context);
  final ok = await _bookmarksService.toggleHighlight(...);
  await _loadBookmarksForChapter(...);
  if (!mounted) return;  // ✅ Verifica mounted
  ScaffoldMessenger.of(context).showSnackBar(...);  // ❌ MAS usa context diretamente
  setState(() {});
},
```

#### Código de Referência (verse_actions_modal.dart:485-500)
```dart
Future<void> _setHighlight(String hex) async {
  // ...
  final scaffold = ScaffoldMessenger.of(context);  // ✅ Captura ANTES do async
  
  // Operações assíncronas...
  await _processHighlightUpdate(hex, user.id, scaffold);
  
  // Usa scaffold capturado, não context
  scaffold.showSnackBar(...);  // ✅ Seguro
}
```

**Diferença Crítica**:
- ❌ **Problemático**: Captura `context` DEPOIS de `await` → Widget pode estar disposed
- ✅ **Referência**: Captura `ScaffoldMessenger` ANTES de operações assíncronas

---

## 🔧 Correções Necessárias

### Correção 1: Remover Fallback `ilike` Problemático

**Arquivo**: `verses_screen.dart` (linhas 145-155)

```dart
// ❌ REMOVER
if ((fallbackRows as List).isEmpty) {
  fallbackRows = await Supabase.instance.client
      .from('verses')
      .select('id, verse_number')
      .eq('chapter_number', chapter)
      .ilike('book_name', widget.bookName);  // CAUSA ERRO 400
}

// ✅ SUBSTITUIR POR
if ((fallbackRows as List).isEmpty) {
  // Se book_id não funciona, logar erro e retornar vazio
  LogService.error(
    'Nenhum verse_id encontrado para book=${widget.bookId} cap=$chapter',
    null, null, 'VersesScreen'
  );
  return {};
}
```

---

### Correção 2: Remover `onConflict` Explícito

**Arquivo**: `weekly_challenges_service.dart` (linha 52)

```dart
// ❌ ANTES
await _supabase.from('user_challenge_progress').upsert({
  'user_profile_id': user.id,
  'challenge_id': challengeId,
  'current_progress': 0,
  'is_completed': false,
}, onConflict: 'user_profile_id,challenge_id');

// ✅ DEPOIS
await _supabase.from('user_challenge_progress').upsert({
  'user_profile_id': user.id,
  'challenge_id': challengeId,
  'current_progress': 0,
  'is_completed': false,
});  // Supabase detecta UNIQUE constraint automaticamente
```

---

### Correção 3: Capturar ScaffoldMessenger Antes de Async

**Arquivo**: `verses_screen.dart` (múltiplas ocorrências)

#### Exemplo 1: toggleHighlight (linha 348)
```dart
// ❌ ANTES
onPressed: () async {
  Navigator.pop(context);
  final ok = await _bookmarksService.toggleHighlight(...);
  await _loadBookmarksForChapter(...);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(...);  // ERRO
  setState(() {});
},

// ✅ DEPOIS
onPressed: () async {
  final messenger = ScaffoldMessenger.of(context);  // Captura ANTES
  Navigator.pop(context);
  final ok = await _bookmarksService.toggleHighlight(...);
  await _loadBookmarksForChapter(...);
  if (!mounted) return;
  messenger.showSnackBar(...);  // Usa capturado
  setState(() {});
},
```

---

## 📊 Comparação: Implementação Problemática vs Referência

| Aspecto | Problemático (verses_screen.dart) | Referência (verse_actions_modal.dart) |
|---------|-----------------------------------|---------------------------------------|
| **Query Complexa** | `ilike` sem wildcards → Erro 400 | RPC function → Funciona |
| **Upsert** | `onConflict: 'col1,col2'` → Erro 400 | Omite parâmetro → Funciona |
| **Context Async** | `ScaffoldMessenger.of(context)` após `await` | Captura `messenger` ANTES de `await` |
| **Cache** | Não usa cache local | `HighlightCache` para performance |
| **Animações** | Nenhuma | `AnimationController` para UX |

---

## ✅ Checklist de Correções

- [ ] **Correção 1**: Remover fallback `ilike` em `_loadVerseIds()`
- [ ] **Correção 2**: Remover `onConflict` explícito em `ensureUserChallengeRow()`
- [ ] **Correção 3**: Capturar `ScaffoldMessenger` antes de async (4 locais)
- [ ] **Teste**: Verificar que queries não retornam 400
- [ ] **Teste**: Confirmar que SnackBars aparecem sem erros

---

## 📝 Resumo Executivo

**3 bugs críticos identificados**:
1. ❌ Query `ilike` malformada → Remover fallback problemático
2. ❌ `onConflict` com formato incorreto → Omitir parâmetro
3. ❌ Acesso a `context` após async → Capturar `ScaffoldMessenger` antes

**Impacto**: Todos os 3 bugs causam falhas visíveis ao usuário (erros 400, crashes).

**Prioridade**: 🔴 ALTA - Corrigir imediatamente.

**Tempo estimado**: 30 minutos para aplicar todas as correções.
