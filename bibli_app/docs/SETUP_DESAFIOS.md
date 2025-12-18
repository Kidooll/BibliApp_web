# Guia de Implementação - Desafios Semanais Automatizados

## 🚀 Setup Rápido (15 minutos)

### Passo 1: Executar SQL no Supabase (5 min)
1. Acesse: https://app.supabase.com
2. Vá em **SQL Editor**
3. Cole o conteúdo de `docs/weekly_challenges_automation.sql`
4. Clique em **Run**
5. Verifique se as tabelas foram criadas

### Passo 2: Deploy Edge Function (5 min)
```bash
# Instalar Supabase CLI
npm install -g supabase

# Login
supabase login

# Link ao projeto
supabase link --project-ref seu-projeto-id

# Deploy function
supabase functions deploy weekly-challenges-cron
```

### Passo 3: Configurar Cron Job (5 min)
**Opção A: cron-job.org (Gratuito)**
1. Acesse: https://cron-job.org
2. Crie conta gratuita
3. Adicione novo cron job:
   - **URL**: `https://seu-projeto.supabase.co/functions/v1/weekly-challenges-cron`
   - **Schedule**: `0 0 * * 1` (Segunda 00:00)
   - **Headers**: 
     - `Authorization: Bearer SEU_SERVICE_ROLE_KEY`

**Opção B: GitHub Actions (Gratuito)**
```yaml
# .github/workflows/weekly-challenges.yml
name: Generate Weekly Challenges
on:
  schedule:
    - cron: '0 0 * * 1'  # Segunda 00:00 UTC
  workflow_dispatch:

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - name: Call Edge Function
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_KEY }}" \
            https://seu-projeto.supabase.co/functions/v1/weekly-challenges-cron
```

## ✅ Verificação

### Testar Manualmente
```bash
# Chamar Edge Function diretamente
curl -X POST \
  -H "Authorization: Bearer SEU_SERVICE_ROLE_KEY" \
  https://seu-projeto.supabase.co/functions/v1/weekly-challenges-cron
```

### Verificar no Supabase
```sql
-- Ver desafios gerados
SELECT * FROM weekly_challenges 
WHERE is_active = true 
ORDER BY created_at DESC;

-- Ver templates disponíveis
SELECT * FROM weekly_challenge_templates 
WHERE is_active = true;
```

## 🔧 Manutenção

### Adicionar Novos Templates
```sql
INSERT INTO weekly_challenge_templates 
(title, description, challenge_type, target_value, xp_reward, difficulty) 
VALUES 
('Novo Desafio', 'Descrição', 'reading', 5, 100, 'medium');
```

### Desativar Template
```sql
UPDATE weekly_challenge_templates 
SET is_active = false 
WHERE id = 'uuid-do-template';
```

### Forçar Geração Manual
```sql
SELECT generate_weekly_challenges();
```

## 📊 Monitoramento

### Logs da Edge Function
```bash
supabase functions logs weekly-challenges-cron
```

### Métricas Importantes
- Desafios gerados por semana: 3
- Taxa de conclusão: > 30%
- Engajamento: > 50% dos usuários ativos

## 🐛 Troubleshooting

### Desafios não estão sendo gerados
1. Verificar se Edge Function está deployada
2. Verificar logs: `supabase functions logs`
3. Testar manualmente com curl
4. Verificar se cron job está ativo

### Desafios duplicados
```sql
-- Limpar duplicatas
DELETE FROM weekly_challenges 
WHERE id NOT IN (
  SELECT MIN(id) 
  FROM weekly_challenges 
  GROUP BY title, week_start_date
);
```

### Performance lenta
```sql
-- Recriar índices
REINDEX TABLE weekly_challenges;
REINDEX TABLE weekly_challenge_templates;
```

## 💡 Dicas

1. **Variedade**: Mantenha pelo menos 15 templates ativos
2. **Dificuldade**: Balance entre fácil (40%), médio (40%), difícil (20%)
3. **Recompensas**: Ajuste XP baseado em feedback dos usuários
4. **Testes**: Sempre teste em staging antes de produção

---

**Resultado**: Sistema 100% automatizado que gera desafios semanais sem intervenção manual!