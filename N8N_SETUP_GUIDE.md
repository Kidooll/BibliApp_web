# Guia de Setup: n8n + IA para Desafios Semanais

## ✅ Status do App

**O app JÁ ESTÁ 100% PREPARADO!**

O `WeeklyChallengesService` já busca desafios da tabela `weekly_challenges` do Supabase:
- ✅ `getActiveChallengesThisWeek()` - Busca desafios ativos
- ✅ `getWeeklyChallengesWithProgress()` - Busca com progresso do usuário
- ✅ `incrementByType()` - Incrementa progresso automaticamente
- ✅ `claimChallenge()` - Resgata XP ao completar

**Nenhuma mudança no app é necessária!**

---

## 🚀 Setup n8n (3 opções)

### Opção 1: n8n Cloud (Mais Fácil)
1. Criar conta em https://n8n.io
2. Plano Starter: $20/mês (R$ 100)
3. Importar workflow JSON
4. Configurar credenciais

### Opção 2: Self-Hosted Docker (Recomendado)
```bash
# Instalar n8n
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Acessar
open http://localhost:5678
```

### Opção 3: DigitalOcean/AWS (Produção)
- Droplet: $6/mês (1GB RAM)
- Instalar Docker + n8n
- Configurar domínio e SSL

---

## 📋 Passo a Passo

### 1. Instalar n8n
```bash
# Docker (mais fácil)
docker run -d --name n8n -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n

# Ou via npm
npm install n8n -g
n8n start
```

### 2. Configurar Credenciais

#### OpenAI API
1. Criar conta em https://platform.openai.com
2. Gerar API Key
3. No n8n: Settings → Credentials → Add Credential → OpenAI
4. Colar API Key

#### Supabase Postgres
1. No Supabase: Settings → Database → Connection String
2. Copiar connection string (modo direto, não pooler)
3. No n8n: Settings → Credentials → Add Credential → Postgres
4. Colar connection string

### 3. Importar Workflow
1. No n8n: Workflows → Import from File
2. Selecionar `n8n-workflow-weekly-challenges.json`
3. Workflow será importado

### 4. Configurar Workflow

#### Ajustar Credenciais
- Node "OpenAI - Generate Challenges": Selecionar credencial OpenAI
- Nodes "Supabase": Selecionar credencial Postgres

#### Ajustar Prompt (Opcional)
No node "Prepare Prompt", você pode:
- Modificar quantidade de desafios (padrão: 15)
- Ajustar distribuição de dificuldade
- Adicionar mais temas sazonais
- Personalizar linguagem

#### Notificações (Opcional)
Nodes "Notify Success" e "Notify Error":
- Trocar URL por webhook seu (Discord, Slack, email)
- Ou remover se não quiser notificações

### 5. Testar Workflow
1. Clicar em "Execute Workflow"
2. Verificar cada node (verde = sucesso)
3. Conferir no Supabase se desafios foram inseridos

### 6. Ativar Cron
1. Node "Schedule Trigger" já está configurado
2. Cron: `0 0 * * 1` (Segunda 00:00)
3. Ativar workflow (toggle no topo)

---

## 🎨 Personalizando o Prompt

### Localização do Prompt
Node: **Prepare Prompt** → Código JavaScript

### Exemplos de Customização

#### Adicionar Mais Temas Sazonais
```javascript
if (month === 6) seasonalTheme = 'Dia dos Pais';
else if (month === 5) seasonalTheme = 'Dia das Mães';
else if (month === 10) seasonalTheme = 'Dia das Crianças';
```

#### Mudar Quantidade de Desafios
```javascript
// De 15 para 20 desafios
1. 7 desafios fáceis (target: 2-3, xp: 50-100, coins: 15-30)
2. 7 desafios médios (target: 4-6, xp: 120-180, coins: 35-60)
3. 6 desafios difíceis (target: 7-10, xp: 200-300, coins: 70-100)
```

#### Adicionar Novos Tipos
```javascript
// Adicionar tipo "prayer" (oração)
Tipos de desafios:
- reading: Ler devocionais
- sharing: Compartilhar versículos/citações
- study: Completar estudos bíblicos
- favorite: Adicionar versículos aos favoritos
- note: Escrever reflexões
- prayer: Fazer orações diárias
```

---

## 💰 Custos Reais

### OpenAI API
- Modelo: `gpt-4o-mini` (mais barato)
- Custo: ~$0.15 por 1M tokens de entrada
- Uso semanal: ~1000 tokens = $0.0015
- **Custo mensal: ~R$ 0,30** (4 execuções/mês)

### n8n
- **Cloud**: $20/mês (R$ 100)
- **Self-hosted local**: R$ 0
- **Self-hosted VPS**: R$ 25-50/mês

### Total
- **Mínimo**: R$ 0,30/mês (self-hosted local)
- **Recomendado**: R$ 25/mês (VPS + OpenAI)
- **Máximo**: R$ 100/mês (n8n Cloud + OpenAI)

---

## 🔍 Monitoramento

### Verificar Execuções
1. n8n → Executions
2. Ver histórico de execuções
3. Debugar erros se houver

### Verificar Desafios no Supabase
```sql
-- Ver desafios da próxima semana
SELECT * FROM weekly_challenges 
WHERE start_date > CURRENT_DATE 
ORDER BY start_date;

-- Contar desafios por tipo
SELECT challenge_type, COUNT(*) 
FROM weekly_challenges 
GROUP BY challenge_type;
```

### Logs
```bash
# Ver logs do n8n (Docker)
docker logs -f n8n

# Ver últimas 100 linhas
docker logs --tail 100 n8n
```

---

## 🐛 Troubleshooting

### Erro: "OpenAI API Key inválida"
- Verificar se API Key está correta
- Verificar se tem créditos na conta OpenAI

### Erro: "Supabase connection failed"
- Usar connection string DIRETA (não pooler)
- Verificar se IP está na whitelist (se houver)

### Desafios não aparecem no app
- Verificar se `is_active = true`
- Verificar se datas estão corretas
- Verificar se app está buscando da tabela certa

### IA gera JSON inválido
- Node "Parse AI Response" tem fallbacks
- Se persistir, ajustar prompt para ser mais específico

---

## 📊 Exemplo de Output da IA

```json
[
  {
    "title": "Primeiros Passos na Fé",
    "description": "Leia 3 devocionais curtos esta semana",
    "challenge_type": "reading",
    "target_value": 3,
    "xp_reward": 80,
    "coin_reward": 25
  },
  {
    "title": "Advento Digital",
    "description": "Leia 7 devocionais sobre o nascimento de Jesus",
    "challenge_type": "reading",
    "target_value": 7,
    "xp_reward": 200,
    "coin_reward": 70
  },
  {
    "title": "Compartilhe a Esperança",
    "description": "Compartilhe 5 versículos inspiradores",
    "challenge_type": "sharing",
    "target_value": 5,
    "xp_reward": 150,
    "coin_reward": 50
  }
]
```

---

## 🎯 Próximos Passos

1. ✅ Importar workflow no n8n
2. ✅ Configurar credenciais (OpenAI + Supabase)
3. ✅ Testar execução manual
4. ✅ Ativar cron (Segunda 00:00)
5. ✅ Monitorar primeira execução automática
6. ✅ Ajustar prompt conforme necessário

---

## 📞 Suporte

- **n8n Docs**: https://docs.n8n.io
- **OpenAI Docs**: https://platform.openai.com/docs
- **Community**: https://community.n8n.io

---

**Resultado**: Desafios semanais infinitos, criativos e automáticos por ~R$ 25/mês! 🚀
