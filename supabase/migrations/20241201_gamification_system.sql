-- Migration: Sistema de Gamificação
-- Data: 2024-12-01

-- 1. Tabela de configuração de XP por ação
CREATE TABLE IF NOT EXISTS xp_config (
    id SERIAL PRIMARY KEY,
    action_name VARCHAR(50) UNIQUE NOT NULL,
    xp_amount INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabela de níveis
CREATE TABLE IF NOT EXISTS levels (
    id SERIAL PRIMARY KEY,
    level_number INTEGER UNIQUE NOT NULL,
    level_name VARCHAR(100) NOT NULL,
    xp_required INTEGER NOT NULL,
    description TEXT,
    badge_icon VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Tabela de conquistas
CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    achievement_code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon_name VARCHAR(100),
    xp_reward INTEGER NOT NULL,
    requirement_type VARCHAR(50) NOT NULL, -- 'devotionals_read', 'streak_days', 'highlights', 'chapters_read'
    requirement_value INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tabela de conquistas do usuário
CREATE TABLE IF NOT EXISTS user_achievements (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id INTEGER REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- 5. Tabela de transações de XP (histórico)
CREATE TABLE IF NOT EXISTS xp_transactions (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    xp_amount INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- 'devotional_read', 'achievement_unlocked', 'streak_bonus', 'daily_bonus'
    description TEXT,
    related_id INTEGER, -- ID do devocional, conquista, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Tabela de estatísticas do usuário (cache local)
CREATE TABLE IF NOT EXISTS user_stats (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    total_devotionals_read INTEGER DEFAULT 0,
    current_streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,
    total_highlights INTEGER DEFAULT 0,
    chapters_read_count INTEGER DEFAULT 0,
    last_activity_date DATE,
    last_sync_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir configurações de XP (valores mais difíceis)
INSERT INTO xp_config (action_name, xp_amount, description) VALUES
('devotional_read', 8, 'Ler um devocional diário'),
('daily_bonus', 5, 'Primeira leitura do dia'),
('streak_3_days', 15, 'Bônus por 3 dias seguidos'),
('streak_7_days', 35, 'Bônus por 7 dias seguidos'),
('streak_30_days', 150, 'Bônus por 30 dias seguidos'),
('highlight_verse', 3, 'Destacar um versículo'),
('chapter_read', 5, 'Ler um capítulo da Bíblia'),
('achievement_unlocked', 25, 'Desbloquear uma conquista')
ON CONFLICT (action_name) DO UPDATE SET
    xp_amount = EXCLUDED.xp_amount,
    description = EXCLUDED.description,
    updated_at = NOW();

-- Inserir níveis (mais difíceis)
INSERT INTO levels (level_number, level_name, xp_required, description, badge_icon) VALUES
(1, 'Novato na Fé', 0, 'Bem-vindo à sua jornada espiritual!', 'level_1'),
(2, 'Buscador', 150, 'Você está buscando conhecimento da Palavra.', 'level_2'),
(3, 'Discípulo', 400, 'Um verdadeiro estudante das Escrituras.', 'level_3'),
(4, 'Servo Fiel', 750, 'Sua dedicação é inspiradora!', 'level_4'),
(5, 'Estudioso', 1200, 'Você se tornou um mestre da Palavra!', 'level_5')
ON CONFLICT (level_number) DO UPDATE SET
    level_name = EXCLUDED.level_name,
    xp_required = EXCLUDED.xp_required,
    description = EXCLUDED.description,
    badge_icon = EXCLUDED.badge_icon;

-- Inserir conquistas
INSERT INTO achievements (achievement_code, title, description, icon_name, xp_reward, requirement_type, requirement_value) VALUES
('first_light', 'Primeira Luz', 'Você completou seu primeiro devocional! Que seja o primeiro de muitos encontros com a Palavra.', 'first_light', 25, 'devotionals_read', 1),
('constancy_strength', 'Constância é Força', 'Você completou 7 dias seguidos de devocionais. Um novo hábito está nascendo!', 'constancy_strength', 50, 'streak_days', 7),
('sacred_mark', 'Marcação Sagrada', 'Você destacou seu primeiro versículo. O que toca seu coração merece ser lembrado.', 'sacred_mark', 30, 'highlights', 1),
('word_explorer', 'Explorador da Palavra', 'Você leu versículos de 10 capítulos diferentes. Continue explorando os tesouros escondidos nas Escrituras!', 'word_explorer', 75, 'chapters_read', 10),
('faithful_month', 'Mensal Fiel', '30 dias de devocionais consecutivos! Sua fé é verdadeiramente inspiradora.', 'faithful_month', 100, 'streak_days', 30)
ON CONFLICT (achievement_code) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    icon_name = EXCLUDED.icon_name,
    xp_reward = EXCLUDED.xp_reward,
    requirement_type = EXCLUDED.requirement_type,
    requirement_value = EXCLUDED.requirement_value;

-- Função para atualizar estatísticas do usuário
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar ou inserir estatísticas do usuário
    INSERT INTO user_stats (user_id, total_devotionals_read, current_streak_days, longest_streak_days, total_highlights, chapters_read_count, last_activity_date, updated_at)
    VALUES (NEW.user_profile_id, 1, 1, 1, 0, 0, CURRENT_DATE, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        total_devotionals_read = user_stats.total_devotionals_read + 1,
        last_activity_date = CURRENT_DATE,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar estatísticas quando um devocional é marcado como lido
DROP TRIGGER IF EXISTS update_stats_on_devotional_read ON read_devotionals;
CREATE TRIGGER update_stats_on_devotional_read
    AFTER INSERT ON read_devotionals
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats();

-- Função para calcular XP total do usuário
CREATE OR REPLACE FUNCTION get_user_total_xp(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    total_xp INTEGER;
BEGIN
    SELECT COALESCE(SUM(xp_amount), 0) INTO total_xp
    FROM xp_transactions
    WHERE user_id = user_uuid;
    
    RETURN total_xp;
END;
$$ LANGUAGE plpgsql;

-- Função para obter nível atual do usuário
CREATE OR REPLACE FUNCTION get_user_current_level(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    user_xp INTEGER;
    current_level INTEGER;
BEGIN
    -- Obter XP total do usuário
    SELECT get_user_total_xp(user_uuid) INTO user_xp;
    
    -- Encontrar o nível atual
    SELECT level_number INTO current_level
    FROM levels
    WHERE xp_required <= user_xp
    ORDER BY level_number DESC
    LIMIT 1;
    
    RETURN COALESCE(current_level, 1);
END;
$$ LANGUAGE plpgsql;

-- Função para obter XP necessário para o próximo nível
CREATE OR REPLACE FUNCTION get_xp_to_next_level(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    user_xp INTEGER;
    next_level_xp INTEGER;
BEGIN
    -- Obter XP total do usuário
    SELECT get_user_total_xp(user_uuid) INTO user_xp;
    
    -- Encontrar XP necessário para o próximo nível
    SELECT xp_required INTO next_level_xp
    FROM levels
    WHERE xp_required > user_xp
    ORDER BY level_number ASC
    LIMIT 1;
    
    -- Se não há próximo nível, retornar 0
    RETURN COALESCE(next_level_xp - user_xp, 0);
END;
$$ LANGUAGE plpgsql;

-- Índices para performance
DROP INDEX IF EXISTS idx_xp_transactions_user_id;
CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_id ON xp_transactions(user_id);

DROP INDEX IF EXISTS idx_xp_transactions_created_at;
CREATE INDEX IF NOT EXISTS idx_xp_transactions_created_at ON xp_transactions(created_at);

DROP INDEX IF EXISTS idx_user_achievements_user_id;
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);

DROP INDEX IF EXISTS idx_user_stats_user_id;
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON user_stats(user_id);

DROP INDEX IF EXISTS idx_levels_xp_required;
CREATE INDEX IF NOT EXISTS idx_levels_xp_required ON levels(xp_required);

DROP INDEX IF EXISTS idx_read_devotionals_user_date;
CREATE INDEX IF NOT EXISTS idx_read_devotionals_user_date ON read_devotionals(user_profile_id, devotional_id, read_at);

-- Comentários
COMMENT ON TABLE xp_config IS 'Configurações de XP para diferentes ações no app';
COMMENT ON TABLE levels IS 'Definição dos níveis e XP necessário para cada um';
COMMENT ON TABLE achievements IS 'Conquistas disponíveis no app';
COMMENT ON TABLE user_achievements IS 'Conquistas desbloqueadas por cada usuário';
COMMENT ON TABLE xp_transactions IS 'Histórico de todas as transações de XP';
COMMENT ON TABLE user_stats IS 'Estatísticas e cache local dos usuários';
