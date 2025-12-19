-- Sistema de Desafios Semanais Automatizado
-- Executar no Supabase SQL Editor
-- USA APENAS: weekly_challenges (tabela existente)

-- Nota: weekly_challenges já existe com estrutura:
-- id, title, description, start_date, end_date, challenge_type,
-- target_value, xp_reward, coin_reward, is_active, created_at, updated_at

-- Função para desativar desafios expirados
CREATE OR REPLACE FUNCTION cleanup_expired_challenges()
RETURNS json AS $$
DECLARE
  desativados INT := 0;
  today DATE := CURRENT_DATE;
BEGIN
  -- Desativar desafios que passaram da data de término
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

-- Função para limpar progresso de desafios muito antigos (> 90 dias)
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

-- Função combinada: desativar expirados + limpar antigos
CREATE OR REPLACE FUNCTION maintain_challenges()
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  -- Desativar expirados
  SELECT cleanup_expired_challenges() INTO result;
  
  -- Limpar progresso antigo
  PERFORM cleanup_old_progress();
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Testar funções
SELECT maintain_challenges();

-- Comentários
COMMENT ON FUNCTION cleanup_expired_challenges() IS 'Desativa desafios com end_date < hoje';
COMMENT ON FUNCTION cleanup_old_progress() IS 'Remove progresso de desafios > 90 dias';
COMMENT ON FUNCTION maintain_challenges() IS 'Manutenção completa: desativa expirados + limpa antigos';

-- Verificar desafios expirados
SELECT id, title, end_date, is_active
FROM weekly_challenges
WHERE end_date < CURRENT_DATE AND is_active = true;