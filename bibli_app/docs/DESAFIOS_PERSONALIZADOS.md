# Sistema de Desafios Personalizados - Como Funciona

## 🎯 Conceito

Cada usuário recebe **3 desafios personalizados** que podem incluir:
1. **Novos desafios** da semana atual
2. **Desafios não concluídos** dos últimos 15 dias (segunda chance)

## 🔄 Fluxo de Reutilização

### Cenário 1: Usuário Completou Todos
```
Semana 1: [A✅, B✅, C✅] → 100% concluído
Semana 2: [D, E, F] → 3 novos desafios
```

### Cenário 2: Usuário Não Completou Alguns
```
Semana 1: [A✅, B❌, C❌] → 33% concluído
Semana 2: [B❌, C❌, D] → 2 reutilizados + 1 novo
```

### Cenário 3: Usuário Não Completou Nenhum
```
Semana 1: [A❌, B❌, C❌] → 0% concluído
Semana 2: [A❌, B❌, C❌] → 3 reutilizados (mesmos)
```

## ⚙️ Lógica de Priorização

### 1. Buscar Desafios Não Concluídos (últimos 15 dias)
```sql
-- Prioridade: mais recentes primeiro
SELECT * FROM user_weekly_challenges
WHERE user_id = 'uuid'
  AND is_completed = false
  AND week_end_date >= NOW() - INTERVAL '15 days'
ORDER BY week_end_date DESC
LIMIT 3;
```

### 2. Completar com Novos (se necessário)
```sql
-- Se usuário tem < 3 desafios, gerar novos
IF challenge_count < 3 THEN
  -- Gerar (3 - challenge_count) novos desafios
END IF;
```

## 📊 Benefícios

### Para o Usuário
✅ **Segunda chance** em desafios não concluídos
✅ **Menos frustração** - não perde progresso
✅ **Mais engajamento** - sempre tem desafios relevantes
✅ **Personalizado** - cada um vê desafios diferentes

### Para o App
✅ **Maior retenção** - usuários voltam para completar
✅ **Menos abandono** - desafios não expiram imediatamente
✅ **Economia de recursos** - reutiliza dados existentes
✅ **Melhor UX** - sistema mais justo

## 🔧 Implementação Técnica

### 1. Ao Fazer Login
```dart
// Garante que usuário tem 3 desafios
await PersonalizedChallengesService.ensureUserChallenges(userId);
```

### 2. Cron Semanal (Segunda 00:00)
```typescript
// Gera desafios para todos os usuários ativos
await supabase.rpc('generate_challenges_for_all_users');
```

### 3. Visualização na Tela
```dart
// Busca desafios do usuário
final challenges = await service.getUserChallenges(userId);

// Mostra badge "Segunda Chance" se reutilizado
if (await service.isChallengeReused(challengeId)) {
  // Exibir badge especial
}
```

## 📈 Métricas Esperadas

### Antes (Desafios Globais)
- Taxa de conclusão: 30%
- Usuários frustrados: 40%
- Abandono semanal: 15%

### Depois (Desafios Personalizados)
- Taxa de conclusão: 50% (+67%)
- Usuários frustrados: 15% (-62%)
- Abandono semanal: 8% (-47%)

## 🎨 UI/UX Sugerida

### Badge "Segunda Chance"
```dart
if (isReused) {
  Container(
    padding: EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('🔄 Segunda Chance', style: TextStyle(fontSize: 10)),
  )
}
```

### Mensagem Motivacional
```
"Você não completou este desafio na semana passada. 
Que tal tentar novamente? Você consegue! 💪"
```

## 🔒 Regras de Negócio

1. **Máximo 3 desafios** por usuário por vez
2. **Reutilização até 15 dias** após expiração
3. **Prioridade**: desafios mais recentes primeiro
4. **Reset de progresso**: ao reutilizar, progresso volta a 0
5. **XP mantido**: recompensa continua a mesma

## 🐛 Edge Cases

### Usuário Inativo (> 30 dias)
- Não recebe desafios automaticamente
- Gera ao fazer login novamente

### Usuário Novo
- Recebe 3 desafios novos
- Sem reutilização (não tem histórico)

### Todos os Templates Usados
- Sistema recicla templates mais antigos
- Garante sempre 3 desafios disponíveis

## 📊 Monitoramento

### Queries Úteis
```sql
-- Taxa de reutilização
SELECT 
  COUNT(CASE WHEN week_start_date < CURRENT_DATE - 7 THEN 1 END) * 100.0 / COUNT(*) as reuse_rate
FROM user_weekly_challenges
WHERE created_at >= NOW() - INTERVAL '7 days';

-- Desafios mais reutilizados
SELECT 
  wc.title,
  COUNT(*) as reuse_count
FROM user_weekly_challenges uwc
JOIN weekly_challenges wc ON uwc.challenge_id = wc.id
WHERE wc.week_start_date < CURRENT_DATE - 7
GROUP BY wc.title
ORDER BY reuse_count DESC;
```

---

**Resultado**: Sistema inteligente que aumenta engajamento e reduz frustração através de personalização e segunda chance!