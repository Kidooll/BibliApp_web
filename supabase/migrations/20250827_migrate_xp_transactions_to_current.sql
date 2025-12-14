-- Padronização de xp_transactions para o esquema atual
-- Esquema atual: user_id (uuid), xp_amount (int), transaction_type (text), description (text), related_id (int), created_at (timestamptz)

BEGIN;

-- Criar tabela se não existir (esquema atual)
CREATE TABLE IF NOT EXISTS public.xp_transactions (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  xp_amount INTEGER NOT NULL,
  transaction_type VARCHAR(50) NOT NULL,
  description TEXT,
  related_id INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backfill de colunas atuais a partir do esquema legado, se necessário
-- Adiciona colunas atuais se faltarem
ALTER TABLE public.xp_transactions ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.xp_transactions ADD COLUMN IF NOT EXISTS xp_amount INTEGER;
ALTER TABLE public.xp_transactions ADD COLUMN IF NOT EXISTS transaction_type VARCHAR(50);
ALTER TABLE public.xp_transactions ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.xp_transactions ADD COLUMN IF NOT EXISTS related_id INTEGER;
ALTER TABLE public.xp_transactions ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Normalizar tipos legados (enums -> texto) antes de copiar valores
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'xp_transactions' AND column_name = 'transaction_type'
      AND data_type = 'USER-DEFINED'
  ) THEN
    ALTER TABLE public.xp_transactions
    ALTER COLUMN transaction_type TYPE VARCHAR(50)
    USING transaction_type::text;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'xp_transactions' AND column_name = 'source_type'
      AND data_type = 'USER-DEFINED'
  ) THEN
    ALTER TABLE public.xp_transactions
    ALTER COLUMN source_type TYPE VARCHAR(50)
    USING source_type::text;
  END IF;
END $$;

-- Se existirem colunas legadas, migra valores para as novas
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'xp_transactions' AND column_name = 'user_profile_id'
  ) THEN
    UPDATE public.xp_transactions SET user_id = COALESCE(user_id, user_profile_id);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'xp_transactions' AND column_name = 'amount'
  ) THEN
    UPDATE public.xp_transactions SET xp_amount = COALESCE(xp_amount, amount);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'xp_transactions' AND column_name = 'source_type'
  ) THEN
    UPDATE public.xp_transactions SET transaction_type = COALESCE(transaction_type, source_type);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'xp_transactions' AND column_name = 'source_id'
  ) THEN
    UPDATE public.xp_transactions SET related_id = COALESCE(related_id, source_id);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'xp_transactions' AND column_name = 'transaction_date'
  ) THEN
    UPDATE public.xp_transactions SET created_at = COALESCE(created_at, transaction_date);
  END IF;
END $$;

-- Remover colunas legadas se existirem
ALTER TABLE public.xp_transactions DROP COLUMN IF EXISTS user_profile_id;
ALTER TABLE public.xp_transactions DROP COLUMN IF EXISTS amount;
ALTER TABLE public.xp_transactions DROP COLUMN IF EXISTS source_type;
ALTER TABLE public.xp_transactions DROP COLUMN IF EXISTS source_id;
ALTER TABLE public.xp_transactions DROP COLUMN IF EXISTS transaction_date;

-- Índices e RLS
DROP INDEX IF EXISTS public.idx_xp_transactions_user_id;
CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_id ON public.xp_transactions(user_id);

DROP INDEX IF EXISTS public.idx_xp_transactions_created_at;
CREATE INDEX IF NOT EXISTS idx_xp_transactions_created_at ON public.xp_transactions(created_at);

-- RLS
ALTER TABLE public.xp_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS xp_insert_own ON public.xp_transactions;
CREATE POLICY xp_insert_own ON public.xp_transactions
FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS xp_select_own ON public.xp_transactions;
CREATE POLICY xp_select_own ON public.xp_transactions
FOR SELECT TO authenticated
USING (user_id = auth.uid());

COMMIT;
