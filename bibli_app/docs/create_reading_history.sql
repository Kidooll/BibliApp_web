-- Criar tabela reading_history para rastrear histórico de leituras
-- Executar no Supabase SQL Editor

CREATE TABLE IF NOT EXISTS reading_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  devotional_id INTEGER NOT NULL REFERENCES devotionals(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraint para evitar duplicatas (um devocional por dia por usuário)
  CONSTRAINT reading_history_unique UNIQUE (user_id, devotional_id, read_date)
);

-- Índices para otimizar queries
CREATE INDEX IF NOT EXISTS idx_reading_history_user_id ON reading_history(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_history_read_date ON reading_history(read_date);
CREATE INDEX IF NOT EXISTS idx_reading_history_user_date ON reading_history(user_id, read_date);

-- Habilitar RLS (Row Level Security)
ALTER TABLE reading_history ENABLE ROW LEVEL SECURITY;

-- Policy: Usuários podem ver apenas seu próprio histórico
CREATE POLICY "Users can view own reading history"
  ON reading_history
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Usuários podem inserir apenas seu próprio histórico
CREATE POLICY "Users can insert own reading history"
  ON reading_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Comentários
COMMENT ON TABLE reading_history IS 'Histórico de leituras de devocionais para exibição no calendário';
COMMENT ON COLUMN reading_history.user_id IS 'ID do usuário que leu o devocional';
COMMENT ON COLUMN reading_history.devotional_id IS 'ID do devocional lido';
COMMENT ON COLUMN reading_history.read_at IS 'Data e hora da leitura';
COMMENT ON COLUMN reading_history.read_date IS 'Data da leitura (sem hora) para calendário';

-- Migrar dados existentes de read_devotionals (se houver)
INSERT INTO reading_history (user_id, devotional_id, read_at, read_date, created_at)
SELECT 
  user_profile_id as user_id,
  devotional_id,
  read_at,
  DATE(read_at) as read_date,
  read_at as created_at
FROM read_devotionals
ON CONFLICT (user_id, devotional_id, read_date) DO NOTHING;

-- Verificar dados migrados
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users,
  MIN(read_at) as first_read,
  MAX(read_at) as last_read
FROM reading_history;
