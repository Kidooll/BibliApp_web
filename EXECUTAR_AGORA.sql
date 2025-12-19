-- EXECUTAR NO SUPABASE SQL EDITOR
-- Copie e cole este SQL completo

-- 1. Função para desativar desafios expirados
CREATE OR REPLACE FUNCTION cleanup_expired_challenges()
RETURNS json AS $$
DECLARE
  desativados INT := 0;
  today DATE := CURRENT_DATE;
BEGIN
  UPDATE weekly_challenges
  SET is_active = false, updated_at = NOW()
  WHERE is_active = true AND end_date < today;
  
  GET DIAGNOSTICS desativados = ROW_COUNT;

  RETURN json_build_object(
    'success', true,
    'desativados', desativados,
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql;

-- 2. Função para limpar progresso antigo
CREATE OR REPLACE FUNCTION cleanup_old_progress()
RETURNS void AS $$
BEGIN
  DELETE FROM user_challenge_progress 
  WHERE challenge_id IN (
    SELECT id FROM weekly_challenges 
    WHERE end_date < CURRENT_DATE - INTERVAL '90 days'
  );
END;
$$ LANGUAGE plpgsql;

-- 3. Função combinada (ESTA É A QUE O N8N CHAMA)
CREATE OR REPLACE FUNCTION maintain_challenges()
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT cleanup_expired_challenges() INTO result;
  PERFORM cleanup_old_progress();
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 4. Testar se funcionou
SELECT maintain_challenges();

-- 5. Verificar se função existe
SELECT proname, proargnames, prosrc 
FROM pg_proc 
WHERE proname = 'maintain_challenges';
