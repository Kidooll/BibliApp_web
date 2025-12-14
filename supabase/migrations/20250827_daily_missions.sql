-- Daily Missions (Missões Diárias) schema
-- Cria tabelas e seeds básicos para missões diárias

BEGIN;

-- Tabela de missões diárias catalogadas
CREATE TABLE IF NOT EXISTS public.daily_missions (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  xp_reward INTEGER NOT NULL DEFAULT 5,
  coin_reward INTEGER NOT NULL DEFAULT 0,
  frequency TEXT NOT NULL DEFAULT 'daily', -- reservado para futuro ('daily','weekly')
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabela de estado de missões por usuário por dia
CREATE TABLE IF NOT EXISTS public.user_missions (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  mission_id INTEGER REFERENCES public.daily_missions(id) ON DELETE CASCADE,
  mission_date DATE NOT NULL DEFAULT CURRENT_DATE,
  progress INTEGER NOT NULL DEFAULT 0,
  target INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'completed' | 'claimed'
  completed_at TIMESTAMPTZ,
  claimed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, mission_id, mission_date)
);

-- Índices auxiliares
CREATE INDEX IF NOT EXISTS idx_user_missions_user_date ON public.user_missions(user_id, mission_date);
CREATE INDEX IF NOT EXISTS idx_user_missions_status ON public.user_missions(status);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION public.set_user_missions_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_missions_updated_at ON public.user_missions;
CREATE TRIGGER trg_user_missions_updated_at
BEFORE UPDATE ON public.user_missions
FOR EACH ROW
EXECUTE FUNCTION public.set_user_missions_updated_at();

-- Seeds de missões diárias (idempotentes)
INSERT INTO public.daily_missions (code, title, description, xp_reward, coin_reward)
VALUES
  ('read_today_devotional', 'Ler o devocional de hoje', 'Complete a leitura do devocional diário.', 8, 0),
  ('open_bible', 'Abrir a Bíblia', 'Abra a seção da Bíblia no app hoje.', 3, 0),
  ('share_quote', 'Compartilhar uma citação', 'Compartilhe uma citação do dia.', 5, 0),
  ('streak_check', 'Manter a sequência', 'Volte hoje para manter sua sequência.', 4, 0)
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  xp_reward = EXCLUDED.xp_reward,
  coin_reward = EXCLUDED.coin_reward,
  is_active = true;

COMMIT;
