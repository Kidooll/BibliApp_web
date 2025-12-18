-- Tabela para eventos de analytics (executar no Supabase SQL Editor)

CREATE TABLE IF NOT EXISTS app_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_name TEXT NOT NULL,
  event_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_app_events_user_id ON app_events(user_id);
CREATE INDEX IF NOT EXISTS idx_app_events_event_name ON app_events(event_name);
CREATE INDEX IF NOT EXISTS idx_app_events_created_at ON app_events(created_at);

-- RLS (Row Level Security)
ALTER TABLE app_events ENABLE ROW LEVEL SECURITY;

-- Política: usuários podem inserir seus próprios eventos
CREATE POLICY "Users can insert their own events" ON app_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política: usuários podem ver seus próprios eventos
CREATE POLICY "Users can view their own events" ON app_events
  FOR SELECT USING (auth.uid() = user_id);

-- Função para limpeza automática (eventos > 90 dias)
CREATE OR REPLACE FUNCTION cleanup_old_events()
RETURNS void AS $$
BEGIN
  DELETE FROM app_events 
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON TABLE app_events IS 'Eventos de analytics do BibliApp';
COMMENT ON COLUMN app_events.event_name IS 'Nome do evento (ex: devotional_read, level_up)';
COMMENT ON COLUMN app_events.event_data IS 'Dados adicionais do evento em JSON';