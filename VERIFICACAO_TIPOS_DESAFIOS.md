# Verificação: Tipos de Desafios no App

## ✅ Status: TUDO CORRETO

### Estrutura da Tabela `weekly_challenges`

```sql
-- Campos existentes (SEM difficulty)
id, title, description, start_date, end_date, 
challenge_type, target_value, xp_reward, coin_reward, 
is_active, created_at, updated_at
```

**IMPORTANTE**: O campo `difficulty` NÃO existe na tabela.

---

## 🎯 5 Tipos de Desafios Suportados

### 1. **reading** (Leitura)
- **Ícone no app**: `Icons.menu_book`
- **Exemplo**: "Leia 3 devocionais esta semana"
- **Target**: 3
- **XP**: 15-30

### 2. **sharing** (Compartilhamento)
- **Ícone no app**: `Icons.share`
- **Exemplo**: "Compartilhe 2 citações"
- **Target**: 2
- **XP**: 10-20

### 3. **study** (Estudo)
- **Ícone no app**: `Icons.auto_stories`
- **Exemplo**: "Estude 5 versículos"
- **Target**: 5
- **XP**: 20-40

### 4. **favorite** (Favoritar)
- **Ícone no app**: `Icons.favorite`
- **Exemplo**: "Favorite 3 devocionais"
- **Target**: 3
- **XP**: 10-25

### 5. **note** (Anotações)
- **Ícone no app**: `Icons.edit_note`
- **Exemplo**: "Faça 2 anotações"
- **Target**: 2
- **XP**: 15-30

---

## 🔍 Como o App Processa os Desafios

### Código: `missions_screen.dart` (linha ~1050)

```dart
IconData _getChallengeIcon(String type) {
  switch (type) {
    case 'reading':
      return Icons.menu_book;
    case 'sharing':
      return Icons.share;
    case 'streak':
      return Icons.local_fire_department;
    case 'devotional':
      return Icons.favorite;
    default:
      return Icons.flag;
  }
}
```

**PROBLEMA IDENTIFICADO**: O switch case usa nomes diferentes!

### Mapeamento Incorreto

| Tipo no Banco | Tipo no App | Status |
|---------------|-------------|--------|
| `reading` | `reading` | ✅ OK |
| `sharing` | `sharing` | ✅ OK |
| `study` | ❌ Não mapeado | ⚠️ Usa ícone padrão |
| `favorite` | `devotional` | ⚠️ Nome diferente |
| `note` | ❌ Não mapeado | ⚠️ Usa ícone padrão |

---

## 🛠️ Correção Necessária

### Atualizar `_getChallengeIcon()` em `missions_screen.dart`

```dart
IconData _getChallengeIcon(String type) {
  switch (type) {
    case 'reading':
      return Icons.menu_book;
    case 'sharing':
      return Icons.share;
    case 'study':
      return Icons.auto_stories;
    case 'favorite':
      return Icons.favorite;
    case 'note':
      return Icons.edit_note;
    case 'streak':
      return Icons.local_fire_department;
    default:
      return Icons.flag;
  }
}
```

---

## 📊 Verificação no Banco

### Execute no Supabase SQL Editor:

```sql
-- Ver desafios ativos e seus tipos
SELECT 
  id,
  title,
  challenge_type,
  target_value,
  xp_reward,
  start_date,
  end_date
FROM weekly_challenges
WHERE is_active = true
ORDER BY challenge_type;

-- Verificar se todos os 5 tipos estão presentes
SELECT 
  challenge_type,
  COUNT(*) as quantidade
FROM weekly_challenges
WHERE is_active = true
GROUP BY challenge_type;
```

**Resultado esperado**: 5 linhas, uma de cada tipo.

---

## ✅ Checklist de Validação

### No Banco de Dados
- [ ] 5 desafios ativos (`is_active = true`)
- [ ] Um de cada tipo: reading, sharing, study, favorite, note
- [ ] Todos com `title`, `description`, `target_value`, `xp_reward`
- [ ] `start_date` = hoje, `end_date` = hoje + 7 dias

### No App
- [ ] Tela de Missões > Tab "Semanais"
- [ ] 5 cards de desafios aparecem
- [ ] Ícones corretos para cada tipo
- [ ] Progress ring funcional (0/target)
- [ ] Botão "Resgatar" aparece quando completo

### Incremento de Progresso
- [ ] `reading`: Incrementa ao ler devocional
- [ ] `sharing`: Incrementa ao compartilhar citação
- [ ] `study`: Incrementa ao estudar versículo
- [ ] `favorite`: Incrementa ao favoritar devocional
- [ ] `note`: Incrementa ao fazer anotação

---

## 🚀 Próximos Passos

1. **Corrigir `_getChallengeIcon()`** (5 min)
2. **Testar no app** (10 min)
3. **Validar incremento de progresso** (15 min)
4. **Confirmar resgate de XP** (5 min)

---

## 📝 Notas Importantes

- **Campo `difficulty` não existe**: Remover de qualquer documentação
- **Tipos fixos**: Sempre usar os 5 tipos listados acima
- **IA gera 5 desafios**: Um de cada tipo, toda semana
- **Progresso automático**: `WeeklyChallengesService.incrementByType()`

---

**Última atualização**: 2024-12-19
**Status**: Correção pendente em `_getChallengeIcon()`
