-- Evitar leitura duplicada do mesmo devocional no mesmo dia por usuário
-- Implementação: coluna normal read_date + trigger para preenchimento + UNIQUE

BEGIN;

-- 1) Adiciona coluna de data (se ainda não existir)
ALTER TABLE public.read_devotionals
ADD COLUMN IF NOT EXISTS read_date date;

-- 2) Backfill para registros existentes
UPDATE public.read_devotionals
SET read_date = (read_at AT TIME ZONE 'UTC')::date
WHERE read_date IS NULL;

-- 3) Função de trigger para manter read_date em INSERT/UPDATE
CREATE OR REPLACE FUNCTION public.set_read_devotionals_read_date()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.read_date := (NEW.read_at AT TIME ZONE 'UTC')::date;
  RETURN NEW;
END;
$$;

-- 4) (Re)cria trigger
DROP TRIGGER IF EXISTS trg_set_read_date ON public.read_devotionals;
CREATE TRIGGER trg_set_read_date
BEFORE INSERT OR UPDATE ON public.read_devotionals
FOR EACH ROW
EXECUTE FUNCTION public.set_read_devotionals_read_date();

-- 5) Remove constraints/índices antigos, se existirem
ALTER TABLE public.read_devotionals
DROP CONSTRAINT IF EXISTS ux_read_once_per_day;
DROP INDEX IF EXISTS public.ux_read_once_per_day;
DROP INDEX IF EXISTS public.ux_read_once_per_day_expr;

-- 5.1) Remover registros duplicados, mantendo o mais antigo por dia
WITH rows AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_profile_id, devotional_id, read_date
      ORDER BY read_at ASC, id ASC
    ) AS rn
  FROM public.read_devotionals
  WHERE read_date IS NOT NULL
)
DELETE FROM public.read_devotionals r
USING rows d
WHERE r.id = d.id
  AND d.rn > 1;

-- 6) Cria UNIQUE garantindo 1 leitura por dia por devocional por usuário
ALTER TABLE public.read_devotionals
ADD CONSTRAINT ux_read_once_per_day UNIQUE (user_profile_id, devotional_id, read_date);

COMMENT ON COLUMN public.read_devotionals.read_date IS 'Data (UTC) derivada de read_at via trigger, para garantir 1 leitura por dia';
COMMENT ON CONSTRAINT ux_read_once_per_day ON public.read_devotionals IS 'Impede leituras duplicadas do mesmo devocional no mesmo dia por usuário';

COMMIT;
