-- Sistema de Desafios Semanais Automatizado
-- Executar no Supabase SQL Editor

-- 1. Tabela de templates de desafios (reutilizáveis)
CREATE TABLE IF NOT EXISTS weekly_challenge_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  challenge_type TEXT NOT NULL, -- 'reading', 'sharing', 'streak', 'missions'
  target_value INTEGER NOT NULL,
  xp_reward INTEGER NOT NULL,
  difficulty TEXT NOT NULL, -- 'easy', 'medium', 'hard'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Índices para performance
CREATE INDEX IF NOT EXISTS idx_challenge_templates_type ON weekly_challenge_templates(challenge_type);
CREATE INDEX IF NOT EXISTS idx_challenge_templates_active ON weekly_challenge_templates(is_active);

-- 3. Função para gerar desafios personalizados por usuário
CREATE OR REPLACE FUNCTION generate_personalized_challenges(p_user_id UUID)
RETURNS void AS $$
DECLARE
  current_week_start DATE;
  current_week_end DATE;
  template_record RECORD;
  user_challenge_count INT;
  failed_challenge_id UUID;
BEGIN
  current_week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE;
  current_week_end := current_week_start + INTERVAL '6 days';
  
  -- Verificar quantos desafios ativos o usuário já tem
  SELECT COUNT(*) INTO user_challenge_count
  FROM user_weekly_challenges uwc
  JOIN weekly_challenges wc ON uwc.challenge_id = wc.id
  WHERE uwc.user_id = p_user_id 
    AND wc.week_start_date = current_week_start
    AND uwc.is_completed = false;
  
  -- Se já tem 3 desafios, não gerar mais
  IF user_challenge_count >= 3 THEN
    RETURN;
  END IF;
  
  -- Buscar desafios não concluídos dos últimos 15 dias
  FOR failed_challenge_id IN (
    SELECT wc.id
    FROM weekly_challenges wc
    JOIN user_weekly_challenges uwc ON uwc.challenge_id = wc.id
    WHERE uwc.user_id = p_user_id
      AND uwc.is_completed = false
      AND wc.week_end_date >= CURRENT_DATE - INTERVAL '15 days'
      AND wc.week_end_date < current_week_start
    ORDER BY wc.week_end_date DESC
    LIMIT (3 - user_challenge_count)
  ) LOOP
    -- Reativar desafio para o usuário
    UPDATE user_weekly_challenges
    SET current_progress = 0,
        updated_at = NOW()
    WHERE user_id = p_user_id 
      AND challenge_id = failed_challenge_id;
    
    user_challenge_count := user_challenge_count + 1;
  END LOOP;
  
  -- Completar com novos desafios se necessário
  IF user_challenge_count < 3 THEN
    FOR template_record IN (
      SELECT * FROM weekly_challenge_templates 
      WHERE is_active = true 
      ORDER BY RANDOM() 
      LIMIT (3 - user_challenge_count)
    ) LOOP
      -- Criar novo desafio global
      INSERT INTO weekly_challenges (
        title,
        description,
        challenge_type,
        target_value,
        xp_reward,
        week_start_date,
        week_end_date,
        is_active
      ) VALUES (
        template_record.title,
        template_record.description,
        template_record.challenge_type,
        template_record.target_value,
        template_record.xp_reward,
        current_week_start,
        current_week_end,
        true
      )
      RETURNING id INTO failed_challenge_id;
      
      -- Atribuir ao usuário
      INSERT INTO user_weekly_challenges (
        user_id,
        challenge_id,
        current_progress,
        is_completed
      ) VALUES (
        p_user_id,
        failed_challenge_id,
        0,
        false
      );
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. Função para limpar desafios antigos (> 30 dias)
CREATE OR REPLACE FUNCTION cleanup_old_challenges()
RETURNS void AS $$
BEGIN
  -- Desativar desafios antigos
  UPDATE weekly_challenges 
  SET is_active = false 
  WHERE week_end_date < CURRENT_DATE - INTERVAL '30 days';
  
  -- Limpar progresso de desafios antigos
  DELETE FROM user_weekly_challenges 
  WHERE challenge_id IN (
    SELECT id FROM weekly_challenges 
    WHERE week_end_date < CURRENT_DATE - INTERVAL '90 days'
  );
END;
$$ LANGUAGE plpgsql;

-- 5. Função para gerar desafios para todos os usuários ativos
CREATE OR REPLACE FUNCTION generate_challenges_for_all_users()
RETURNS void AS $$
DECLARE
  user_record RECORD;
BEGIN
  -- Gerar desafios para cada usuário ativo (login nos últimos 30 dias)
  FOR user_record IN (
    SELECT DISTINCT user_id 
    FROM user_stats 
    WHERE last_activity_date >= CURRENT_DATE - INTERVAL '30 days'
  ) LOOP
    PERFORM generate_personalized_challenges(user_record.user_id);
  END LOOP;
  
  -- Limpar desafios antigos
  PERFORM cleanup_old_challenges();
END;
$$ LANGUAGE plpgsql;

-- 6. Inserir templates iniciais de desafios
INSERT INTO weekly_challenge_templates (title, description, challenge_type, target_value, xp_reward, difficulty) VALUES
-- Fáceis (5 desafios)
('Leitor Iniciante', 'Leia 3 devocionais esta semana', 'reading', 3, 50, 'easy'),
('Compartilhador', 'Compartilhe 2 citações esta semana', 'sharing', 2, 40, 'easy'),
('Consistente', 'Mantenha 3 dias de sequência', 'streak', 3, 45, 'easy'),
('Explorador', 'Complete 2 missões diárias', 'missions', 2, 35, 'easy'),
('Dedicado', 'Leia 2 devocionais esta semana', 'reading', 2, 30, 'easy'),

-- Médios (5 desafios)
('Leitor Dedicado', 'Leia 5 devocionais esta semana', 'reading', 5, 100, 'medium'),
('Evangelizador', 'Compartilhe 5 citações esta semana', 'sharing', 5, 90, 'medium'),
('Perseverante', 'Mantenha 5 dias de sequência', 'streak', 5, 120, 'medium'),
('Missionário', 'Complete 5 missões diárias', 'missions', 5, 85, 'medium'),
('Estudioso', 'Leia 4 devocionais esta semana', 'reading', 4, 80, 'medium'),

-- Difíceis (5 desafios)
('Mestre da Palavra', 'Leia 7 devocionais esta semana', 'reading', 7, 200, 'hard'),
('Influenciador', 'Compartilhe 10 citações esta semana', 'sharing', 10, 180, 'hard'),
('Inabalável', 'Mantenha 7 dias de sequência', 'streak', 7, 250, 'hard'),
('Guerreiro', 'Complete 7 missões diárias', 'missions', 7, 170, 'hard'),
('Gigante da Fé', 'Leia todos os dias da semana', 'reading', 7, 300, 'hard')
ON CONFLICT DO NOTHING;

-- 7. Criar extensão pg_cron para automação (se disponível no Supabase)
-- Nota: Verificar se pg_cron está disponível no seu plano Supabase
-- Se não estiver, usar Edge Functions ou cron job externo

-- 6. Função para gerar desafios ao fazer login (lazy loading)
CREATE OR REPLACE FUNCTION ensure_user_challenges(p_user_id UUID)
RETURNS void AS $$
BEGIN
  PERFORM generate_personalized_challenges(p_user_id);
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON TABLE weekly_challenge_templates IS 'Templates reutilizáveis para gerar desafios semanais';
COMMENT ON FUNCTION generate_personalized_challenges(UUID) IS 'Gera 3 desafios personalizados por usuário, reutilizando não concluídos dos últimos 15 dias';
COMMENT ON FUNCTION generate_challenges_for_all_users() IS 'Gera desafios para todos os usuários ativos (cron semanal)';
COMMENT ON FUNCTION ensure_user_challenges(UUID) IS 'Garante que usuário tem desafios ao fazer login';
COMMENT ON FUNCTION cleanup_old_challenges() IS 'Remove desafios e progresso antigos para economizar espaço';