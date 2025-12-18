-- Função SQL para recalcular e atualizar níveis baseado em XP
-- Executar no Supabase SQL Editor

CREATE OR REPLACE FUNCTION recalculate_user_levels()
RETURNS void AS $$
DECLARE
  user_record RECORD;
  v_total_xp INT;
  v_calculated_level INT;
BEGIN
  FOR user_record IN (SELECT id FROM user_profiles) LOOP
    -- Calcular XP total
    SELECT COALESCE(SUM(xp_amount), 0) INTO v_total_xp
    FROM xp_transactions
    WHERE user_id = user_record.id;
    
    -- Calcular nível baseado em XP (10 níveis do PRD)
    v_calculated_level := CASE
      WHEN v_total_xp >= 4001 THEN 10  -- Gigante da Fé
      WHEN v_total_xp >= 3001 THEN 9   -- Mentor
      WHEN v_total_xp >= 2301 THEN 8   -- Líder Espiritual
      WHEN v_total_xp >= 1701 THEN 7   -- Mestre
      WHEN v_total_xp >= 1201 THEN 6   -- Sábio
      WHEN v_total_xp >= 801 THEN 5    -- Estudioso
      WHEN v_total_xp >= 501 THEN 4    -- Servo Fiel
      WHEN v_total_xp >= 251 THEN 3    -- Discípulo
      WHEN v_total_xp >= 101 THEN 2    -- Buscador
      ELSE 1                         -- Novato na Fé
    END;
    
    -- Atualizar user_profiles
    UPDATE user_profiles up
    SET 
      current_level = v_calculated_level,
      total_xp = v_total_xp,
      updated_at = NOW()
    WHERE up.id = user_record.id;
    
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Executar recálculo para todos os usuários
SELECT recalculate_user_levels();

-- Verificar resultados
SELECT 
  id,
  username,
  total_xp,
  current_level,
  CASE
    WHEN total_xp >= 4001 THEN 10
    WHEN total_xp >= 3001 THEN 9
    WHEN total_xp >= 2301 THEN 8
    WHEN total_xp >= 1701 THEN 7
    WHEN total_xp >= 1201 THEN 6
    WHEN total_xp >= 801 THEN 5
    WHEN total_xp >= 501 THEN 4
    WHEN total_xp >= 251 THEN 3
    WHEN total_xp >= 101 THEN 2
    ELSE 1
  END as calculated_level
FROM user_profiles
ORDER BY total_xp DESC;