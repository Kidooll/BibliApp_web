-- Função para desativar desafios expirados e reativar não concluídos
-- Executar no Supabase SQL Editor

CREATE OR REPLACE FUNCTION cleanup_expired_challenges()
RETURNS void AS $$
DECLARE
  today DATE := CURRENT_DATE;
  affected_rows INT;
BEGIN
  -- 1. Desativar desafios que já passaram da data de término
  UPDATE weekly_challenges
  SET 
    is_active = false,
    updated_at = NOW()
  WHERE 
    is_active = true 
    AND end_date < today;
  
  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  IF affected_rows > 0 THEN
    RAISE NOTICE '✅ % desafios expirados foram desativados', affected_rows;
  END IF;

  -- 2. Reativar desafios não concluídos e ajustar datas
  -- Busca desafios que:
  -- - Estão ativos mas com datas antigas
  -- - Usuário não completou (via user_challenge_progress)
  UPDATE weekly_challenges wc
  SET 
    start_date = today,
    end_date = today + INTERVAL '7 days',
    updated_at = NOW()
  WHERE 
    wc.is_active = true
    AND wc.end_date < today
    AND EXISTS (
      SELECT 1 
      FROM user_challenge_progress ucp
      WHERE 
        ucp.challenge_id = wc.id
        AND ucp.is_completed = false
    );
  
  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  IF affected_rows > 0 THEN
    RAISE NOTICE '🔄 % desafios não concluídos foram reativados com novas datas', affected_rows;
  END IF;

END;
$$ LANGUAGE plpgsql;

-- Executar manualmente (teste)
SELECT cleanup_expired_challenges();

-- Agendar para rodar diariamente às 00:00 (via pg_cron)
-- Requer extensão pg_cron habilitada no Supabase
SELECT cron.schedule(
  'cleanup-expired-challenges',
  '0 0 * * *', -- Todo dia às 00:00
  $$SELECT cleanup_expired_challenges();$$
);

-- Verificar jobs agendados
SELECT * FROM cron.job WHERE jobname = 'cleanup-expired-challenges';

-- Remover agendamento (se necessário)
-- SELECT cron.unschedule('cleanup-expired-challenges');

-- Query para verificar desafios expirados
SELECT 
  id,
  title,
  start_date,
  end_date,
  is_active,
  CASE 
    WHEN end_date < CURRENT_DATE THEN 'Expirado'
    WHEN start_date > CURRENT_DATE THEN 'Futuro'
    ELSE 'Ativo'
  END as status
FROM weekly_challenges
WHERE is_active = true
ORDER BY end_date DESC;
