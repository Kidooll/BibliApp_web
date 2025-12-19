-- VERIFICAR DESAFIOS GERADOS PELA IA
-- Executar no Supabase SQL Editor

-- 1. Ver estrutura da tabela weekly_challenges
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'weekly_challenges'
ORDER BY ordinal_position;

-- 2. Verificar desafios ativos (devem ser 5, um de cada tipo)
SELECT 
  id,
  title,
  challenge_type,
  target_value,
  xp_reward,
  start_date,
  end_date,
  is_active,
  created_at
FROM weekly_challenges
WHERE is_active = true
ORDER BY challenge_type;

-- 3. Contar por tipo (deve ter 1 de cada)
SELECT 
  challenge_type,
  COUNT(*) as quantidade,
  SUM(xp_reward) as total_xp
FROM weekly_challenges
WHERE is_active = true
GROUP BY challenge_type
ORDER BY challenge_type;

-- 4. Verificar se todos os 5 tipos existem
SELECT 
  CASE 
    WHEN COUNT(DISTINCT challenge_type) = 5 THEN '✅ TODOS OS 5 TIPOS PRESENTES'
    ELSE '❌ FALTAM TIPOS: ' || (5 - COUNT(DISTINCT challenge_type))::text
  END as status,
  array_agg(DISTINCT challenge_type ORDER BY challenge_type) as tipos_presentes
FROM weekly_challenges
WHERE is_active = true;

-- 5. Tipos esperados vs presentes
WITH tipos_esperados AS (
  SELECT unnest(ARRAY['reading', 'sharing', 'study', 'favorite', 'note']) as tipo
),
tipos_presentes AS (
  SELECT DISTINCT challenge_type as tipo
  FROM weekly_challenges
  WHERE is_active = true
)
SELECT 
  e.tipo as tipo_esperado,
  CASE 
    WHEN p.tipo IS NOT NULL THEN '✅ Presente'
    ELSE '❌ FALTANDO'
  END as status
FROM tipos_esperados e
LEFT JOIN tipos_presentes p ON e.tipo = p.tipo
ORDER BY e.tipo;

-- 6. Validar campos obrigatórios (nenhum NULL)
SELECT 
  id,
  title,
  CASE WHEN title IS NULL THEN '❌' ELSE '✅' END as has_title,
  CASE WHEN description IS NULL THEN '❌' ELSE '✅' END as has_description,
  CASE WHEN challenge_type IS NULL THEN '❌' ELSE '✅' END as has_type,
  CASE WHEN target_value IS NULL THEN '❌' ELSE '✅' END as has_target,
  CASE WHEN xp_reward IS NULL THEN '❌' ELSE '✅' END as has_xp
FROM weekly_challenges
WHERE is_active = true;

-- 7. Verificar se app consegue buscar (query do WeeklyChallengesService)
SELECT 
  id,
  title,
  description,
  challenge_type,
  target_value,
  xp_reward,
  coin_reward,
  start_date,
  end_date,
  is_active
FROM weekly_challenges
WHERE is_active = true
  AND start_date <= CURRENT_DATE
  AND end_date >= CURRENT_DATE
ORDER BY id;
