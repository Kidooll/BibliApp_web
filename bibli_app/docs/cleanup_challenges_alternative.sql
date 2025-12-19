-- Alternativa: Limpeza via Edge Function ou n8n
-- Se pg_cron não estiver disponível no Supabase

-- Função simplificada que pode ser chamada via RPC
CREATE OR REPLACE FUNCTION cleanup_expired_challenges_rpc()
RETURNS json AS $$
DECLARE
  desativados INT := 0;
  reativados INT := 0;
  today DATE := CURRENT_DATE;
BEGIN
  -- Desativar expirados
  UPDATE weekly_challenges
  SET is_active = false, updated_at = NOW()
  WHERE is_active = true AND end_date < today;
  GET DIAGNOSTICS desativados = ROW_COUNT;

  -- Reativar não concluídos (ajustando datas)
  UPDATE weekly_challenges wc
  SET 
    start_date = today,
    end_date = today + INTERVAL '7 days',
    updated_at = NOW()
  WHERE 
    wc.is_active = true
    AND wc.end_date < today
    AND EXISTS (
      SELECT 1 FROM user_challenge_progress ucp
      WHERE ucp.challenge_id = wc.id AND ucp.is_completed = false
    );
  GET DIAGNOSTICS reativados = ROW_COUNT;

  RETURN json_build_object(
    'success', true,
    'desativados', desativados,
    'reativados', reativados,
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Testar
SELECT cleanup_expired_challenges_rpc();
