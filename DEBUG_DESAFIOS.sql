-- DEBUG: Por que desafios não aparecem no app?

-- 1. Ver desafios ativos
SELECT 
  id,
  title,
  challenge_type,
  is_active,
  start_date,
  end_date,
  CURRENT_DATE as hoje,
  CASE 
    WHEN start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE THEN '✅ VÁLIDO'
    WHEN start_date > CURRENT_DATE THEN '⏳ FUTURO'
    WHEN end_date < CURRENT_DATE THEN '❌ EXPIRADO'
  END as status_periodo
FROM weekly_challenges
WHERE is_active = true
ORDER BY start_date;

-- 2. Query EXATA que o app usa (WeeklyChallengesService.getWeeklyChallengesWithProgress)
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

-- 3. Se vazio, verificar todos os desafios
SELECT 
  id,
  title,
  is_active,
  start_date,
  end_date
FROM weekly_challenges
ORDER BY created_at DESC
LIMIT 10;
