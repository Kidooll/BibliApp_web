# Guia: Limpeza Automática de Desafios Expirados

## 🎯 Problema Identificado

Desafios com `end_date` passada continuam com `is_active = true`, causando:
- ❌ Desafios expirados aparecem no app
- ❌ Usuários não conseguem completar desafios antigos
- ❌ Dados desorganizados no banco

## ✅ Solução Implementada

### Função SQL: `cleanup_expired_challenges_rpc()`

**O que faz:**
1. **Desativa desafios expirados**: `end_date < hoje` → `is_active = false`
2. **Reativa desafios não concluídos**: Ajusta datas para +7 dias se usuário não completou

## 🚀 Opções de Implementação

### Opção 1: Agendamento Supabase (pg_cron)

**Pré-requisito**: pg_cron habilitado (planos pagos)

```sql
-- Executar no Supabase SQL Editor
\i cleanup_expired_challenges.sql

-- Verifica se foi agendado
SELECT * FROM cron.job WHERE jobname = 'cleanup-expired-challenges';
```

**Vantagens:**
- ✅ Totalmente automático
- ✅ Roda no banco (sem dependências externas)
- ✅ Confiável

**Desvantagens:**
- ❌ Requer plano pago do Supabase

---

### Opção 2: n8n Workflow (Recomendado)

**Adicionar ao workflow existente:**

```json
{
  "parameters": {
    "operation": "executeQuery",
    "query": "SELECT cleanup_expired_challenges_rpc()"
  },
  "name": "Limpar Desafios Expirados",
  "type": "n8n-nodes-base.postgres",
  "position": [450, 600]
}
```

**Conectar após "Definir Parâmetros":**
```
Definir Parâmetros → Limpar Desafios Expirados → Usar IA?
```

**Vantagens:**
- ✅ Gratuito
- ✅ Integrado ao workflow existente
- ✅ Roda toda segunda-feira automaticamente

---

### Opção 3: Edge Function Supabase

**Criar arquivo:** `supabase/functions/cleanup-challenges/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { data, error } = await supabase.rpc('cleanup_expired_challenges_rpc')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

**Agendar com cron-job.org:**
- URL: `https://seu-projeto.supabase.co/functions/v1/cleanup-challenges`
- Frequência: Diariamente às 00:00
- Header: `Authorization: Bearer YOUR_ANON_KEY`

**Vantagens:**
- ✅ Gratuito
- ✅ Serverless
- ✅ Independente do n8n

---

### Opção 4: Chamada no App (Fallback)

**Adicionar no `WeeklyChallengesService`:**

```dart
Future<void> cleanupExpiredChallenges() async {
  try {
    await _supabase.rpc('cleanup_expired_challenges_rpc');
  } catch (e) {
    LogService.error('Erro ao limpar desafios', e, null, 'WeeklyChallengesService');
  }
}
```

**Chamar ao abrir tela de missões:**

```dart
@override
void initState() {
  super.initState();
  _service.cleanupExpiredChallenges(); // Limpa em background
  _loadChallenges();
}
```

**Vantagens:**
- ✅ Simples
- ✅ Sem configuração externa
- ✅ Funciona sempre que usuário abre o app

**Desvantagens:**
- ❌ Depende de usuário abrir o app
- ❌ Múltiplas chamadas desnecessárias

---

## 📊 Comparação

| Opção | Custo | Confiabilidade | Complexidade |
|-------|-------|----------------|--------------|
| **pg_cron** | Pago | ⭐⭐⭐⭐⭐ | Baixa |
| **n8n** | Grátis | ⭐⭐⭐⭐ | Baixa |
| **Edge Function** | Grátis | ⭐⭐⭐⭐ | Média |
| **App** | Grátis | ⭐⭐⭐ | Baixa |

## 🎯 Recomendação

**Use Opção 2 (n8n)** porque:
1. Você já tem n8n configurado
2. Workflow roda toda segunda-feira
3. Gratuito e confiável
4. Fácil de implementar

## 🔧 Implementação Rápida (n8n)

### Passo 1: Executar SQL
```sql
-- No Supabase SQL Editor
\i cleanup_challenges_alternative.sql
```

### Passo 2: Adicionar Node no n8n

Abrir workflow → Adicionar node após "Definir Parâmetros":

**Node: Supabase RPC**
- Operation: Execute Query
- Query: `SELECT cleanup_expired_challenges_rpc()`

### Passo 3: Testar

Executar workflow manualmente e verificar logs.

---

## 🐛 Troubleshooting

### Erro: "function does not exist"
```sql
-- Verificar se função foi criada
SELECT proname FROM pg_proc WHERE proname LIKE '%cleanup%';
```

### Desafios não estão sendo desativados
```sql
-- Verificar desafios expirados
SELECT id, title, end_date, is_active 
FROM weekly_challenges 
WHERE end_date < CURRENT_DATE AND is_active = true;

-- Executar manualmente
SELECT cleanup_expired_challenges_rpc();
```

### Verificar resultado
```sql
-- Ver resultado da última execução
SELECT * FROM cleanup_expired_challenges_rpc();
```

---

## 📝 Logs

A função retorna JSON com estatísticas:

```json
{
  "success": true,
  "desativados": 5,
  "reativados": 2,
  "timestamp": "2024-12-19T12:00:00Z"
}
```

---

**Resultado**: Desafios sempre atualizados automaticamente! 🚀
