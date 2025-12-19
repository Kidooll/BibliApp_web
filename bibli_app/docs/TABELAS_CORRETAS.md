# Tabelas Corretas do BibliApp

## ✅ Tabelas que o App USA

### 1. `weekly_challenges` (Principal)
```sql
-- Desafios semanais
id, title, description, start_date, end_date, 
challenge_type, target_value, xp_reward, coin_reward,
is_active, created_at, updated_at
```

**Usado por**: `WeeklyChallengesService`

### 2. `weekly_challenges_published`
```sql
-- Controle de publicação
id, challenge_id, start_date, end_date, created_at
```

**Usado por**: Workflow n8n de publicação

### 3. `user_challenge_progress`
```sql
-- Progresso do usuário
id, user_profile_id, challenge_id, 
current_progress, is_completed, completed_at
```

**Usado por**: `WeeklyChallengesService`

---

## ❌ Tabelas que NÃO são usadas

### `weekly_challenge_templates`
- **Status**: Criada por engano no SQL `weekly_challenges_automation.sql`
- **Motivo**: Não é necessária - desafios vão direto para `weekly_challenges`
- **Ação**: Pode ser deletada

```sql
-- Deletar se existir
DROP TABLE IF EXISTS weekly_challenge_templates CASCADE;
```

---

## 🔧 Fluxo Correto

### Sem IA (Atual)
```
CSV → weekly_challenges (manual)
  ↓
Workflow n8n publica → weekly_challenges_published
  ↓
App busca → weekly_challenges (is_active=true)
  ↓
Usuário progride → user_challenge_progress
```

### Com IA (Futuro)
```
IA gera → weekly_challenges (automático)
  ↓
Workflow n8n publica → weekly_challenges_published
  ↓
App busca → weekly_challenges (is_active=true)
  ↓
Usuário progride → user_challenge_progress
```

---

## 📝 Resumo

**Use apenas**:
- ✅ `weekly_challenges`
- ✅ `weekly_challenges_published`  
- ✅ `user_challenge_progress`

**Ignore/Delete**:
- ❌ `weekly_challenge_templates`

---

**Tudo que você precisa já está em `weekly_challenges`!** 🎯
