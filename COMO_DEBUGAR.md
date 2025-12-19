# 🔍 Como Debugar: Desafios Não Aparecem

## Passo 1: Verificar Banco de Dados

Execute `DEBUG_DESAFIOS.sql` no Supabase SQL Editor.

**Resultado esperado:**
```
✅ 5 desafios com status_periodo = 'VÁLIDO'
```

**Se vazio:**
- Desafios não foram gerados pela IA
- Ou `start_date`/`end_date` estão incorretos

---

## Passo 2: Verificar Logs do App

1. Rebuild: `flutter run`
2. Abrir tela de Missões > Tab "Semanais"
3. Ver console/logcat

**Logs esperados:**
```
DEBUG: Hoje = 2024-12-19
DEBUG: Desafios ativos encontrados: 5
DEBUG: Desafio 1: Leia 3 devocionais (2024-12-19 - 2024-12-26)
DEBUG: Desafio 2: Compartilhe 2 citações (2024-12-19 - 2024-12-26)
...
DEBUG: Retornando 5 desafios com progresso
```

**Se aparecer:**
```
DEBUG: Desafios ativos encontrados: 0
DEBUG: Nenhum desafio ativo no período
```

**Problema:** Datas incorretas no banco.

---

## Passo 3: Corrigir Datas (Se Necessário)

```sql
-- Atualizar desafios para semana atual
UPDATE weekly_challenges
SET 
  start_date = CURRENT_DATE,
  end_date = CURRENT_DATE + INTERVAL '7 days',
  is_active = true
WHERE id IN (SELECT id FROM weekly_challenges ORDER BY created_at DESC LIMIT 5);
```

---

## Passo 4: Verificar RLS (Row Level Security)

```sql
-- Ver policies da tabela
SELECT * FROM pg_policies WHERE tablename = 'weekly_challenges';

-- Se não houver policy de SELECT, criar:
CREATE POLICY "Todos podem ver desafios ativos"
ON weekly_challenges FOR SELECT
USING (is_active = true);
```

---

## Passo 5: Testar Query Manualmente

```sql
-- Query EXATA do app
SELECT *
FROM weekly_challenges
WHERE is_active = true
  AND start_date <= CURRENT_DATE
  AND end_date >= CURRENT_DATE
ORDER BY id;
```

Se retornar vazio, o problema é nas datas.

---

## Soluções Rápidas

### Problema: Datas no Futuro
```sql
UPDATE weekly_challenges
SET start_date = CURRENT_DATE
WHERE start_date > CURRENT_DATE;
```

### Problema: Datas no Passado
```sql
UPDATE weekly_challenges
SET end_date = CURRENT_DATE + INTERVAL '7 days'
WHERE end_date < CURRENT_DATE;
```

### Problema: is_active = false
```sql
UPDATE weekly_challenges
SET is_active = true
WHERE id IN (SELECT id FROM weekly_challenges ORDER BY created_at DESC LIMIT 5);
```

---

## Checklist Final

- [ ] SQL retorna 5 desafios
- [ ] Datas válidas (start <= hoje <= end)
- [ ] `is_active = true`
- [ ] RLS policy existe
- [ ] Logs do app mostram desafios encontrados
- [ ] Cards aparecem na tela

---

**Se ainda não funcionar:** Compartilhe os logs do console.
