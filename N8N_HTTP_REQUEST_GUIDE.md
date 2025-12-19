# Guia: HTTP Request para Supabase (AWS-Friendly)

## 🎯 Por que HTTP Request?

Rodando n8n na AWS, **HTTP Request é melhor** que conexão Postgres direta:

✅ **Sem conexão direta ao banco** (mais seguro)  
✅ **Funciona de qualquer lugar** (AWS, local, cloud)  
✅ **Usa Supabase REST API** (nativa)  
✅ **Não precisa configurar Postgres** no n8n  
✅ **Mais rápido** (menos overhead)  

---

## 🔧 Node HTTP Request no n8n

### Configuração

**Type**: HTTP Request  
**Method**: POST  
**URL**: `https://SEU_PROJETO.supabase.co/rest/v1/rpc/maintain_challenges`

### Headers

```json
{
  "Content-Type": "application/json",
  "apikey": "SUA_ANON_KEY",
  "Authorization": "Bearer SUA_SERVICE_ROLE_KEY"
}
```

### Body

```json
{}
```

### Response Esperada

```json
{
  "success": true,
  "desativados": 5,
  "timestamp": "2024-12-19T12:00:00.000Z"
}
```

---

## 📝 Passo a Passo

### 1. Obter Credenciais Supabase

**Supabase Dashboard** → Settings → API

- **Project URL**: `https://seu-projeto.supabase.co`
- **anon/public key**: Para operações públicas
- **service_role key**: Para operações admin (use esta!)

### 2. Criar Node no n8n

1. Adicionar node **HTTP Request**
2. Configurar:
   - **Method**: POST
   - **URL**: `https://seu-projeto.supabase.co/rest/v1/rpc/maintain_challenges`
3. Headers:
   - `Content-Type`: `application/json`
   - `apikey`: `sua_service_role_key`
   - `Authorization`: `Bearer sua_service_role_key`
4. Body: `{}`

### 3. Testar

Execute o node e verifique response:

```json
{
  "success": true,
  "desativados": 3,
  "timestamp": "2024-12-19T..."
}
```

---

## 🔐 Segurança

### ⚠️ IMPORTANTE

- **NUNCA** commitar service_role_key
- Usar **variáveis de ambiente** no n8n
- service_role_key tem **acesso total** ao banco

### Configurar Variável no n8n

1. Settings → Variables
2. Criar: `SUPABASE_SERVICE_ROLE_KEY`
3. Usar no node: `{{ $env.SUPABASE_SERVICE_ROLE_KEY }}`

---

## 🎯 Workflow Completo

```
1. Weekly Trigger (Cron)
   ↓
2. Check Active Challenges (Supabase GET)
   ↓
3. Determine Active Challenge Exists (Code)
   ↓
4. 🆕 HTTP Request: maintain_challenges()
   ↓
5. No Active Challenges? (IF)
   ├─ SIM → Generate New Challenges (OpenAI)
   └─ NÃO → Skip Generation
   ↓
6. Parse New Challenges (Code)
   ↓
7. Save New Challenges (Supabase INSERT)
```

---

## 🐛 Troubleshooting

### Erro: "function does not exist"

```sql
-- Verificar se função foi criada
SELECT proname FROM pg_proc WHERE proname = 'maintain_challenges';

-- Se não existir, executar:
\i weekly_challenges_automation.sql
```

### Erro: "permission denied"

- Verificar se está usando **service_role_key** (não anon key)
- service_role_key tem permissões admin

### Erro: "Invalid API key"

- Verificar se copiou a key completa
- Verificar se não tem espaços extras
- Testar no Postman primeiro

---

## 📊 Comparação

| Método | Segurança | Performance | Setup | AWS-Friendly |
|--------|-----------|-------------|-------|--------------|
| **HTTP Request** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ SIM |
| Postgres Direto | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ❌ NÃO |

---

## ✅ Resultado

**HTTP Request via Supabase REST API** é a melhor solução para:
- ✅ n8n rodando na AWS
- ✅ Segurança (sem conexão direta)
- ✅ Performance (API otimizada)
- ✅ Simplicidade (sem config Postgres)

---

**Pronto para produção!** 🚀
