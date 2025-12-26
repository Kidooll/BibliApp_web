BEGIN;

-- Data atual no fuso de Sao Paulo (Brasil)
CREATE OR REPLACE FUNCTION public.get_sp_date()
RETURNS date
LANGUAGE sql
STABLE
AS $$
  SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date;
$$;

GRANT EXECUTE ON FUNCTION public.get_sp_date() TO authenticated;

-- Atualiza o read_date com base no fuso de Sao Paulo
CREATE OR REPLACE FUNCTION public.set_read_devotionals_read_date()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.read_at IS NULL THEN
    NEW.read_at := now();
  END IF;
  NEW.read_date := (NEW.read_at AT TIME ZONE 'America/Sao_Paulo')::date;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_read_date ON public.read_devotionals;
CREATE TRIGGER trg_set_read_date
BEFORE INSERT OR UPDATE ON public.read_devotionals
FOR EACH ROW
EXECUTE FUNCTION public.set_read_devotionals_read_date();

-- Recalcular read_date para registros existentes (pode alterar por fuso)
ALTER TABLE public.read_devotionals
DROP CONSTRAINT IF EXISTS ux_read_once_per_day;

UPDATE public.read_devotionals
SET read_date = (read_at AT TIME ZONE 'America/Sao_Paulo')::date
WHERE read_at IS NOT NULL;

-- Remover duplicados apos ajuste de fuso
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

ALTER TABLE public.read_devotionals
ADD CONSTRAINT ux_read_once_per_day UNIQUE (user_profile_id, devotional_id, read_date);

COMMENT ON COLUMN public.read_devotionals.read_date IS
  'Data (America/Sao_Paulo) derivada de read_at via trigger, para garantir 1 leitura por dia';

-- RLS para controlar acesso aos devocionais
ALTER TABLE public.devotionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.read_devotionals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS devotionals_select_access ON public.devotionals;
CREATE POLICY devotionals_select_access
ON public.devotionals
FOR SELECT
TO authenticated
USING (
  published_date = public.get_sp_date()
  OR EXISTS (
    SELECT 1
    FROM public.read_devotionals rd
    WHERE rd.devotional_id = devotionals.id
      AND rd.user_profile_id = auth.uid()
      AND rd.read_date = devotionals.published_date
  )
);

DROP POLICY IF EXISTS read_devotionals_select_own ON public.read_devotionals;
CREATE POLICY read_devotionals_select_own
ON public.read_devotionals
FOR SELECT
TO authenticated
USING (user_profile_id = auth.uid());

DROP POLICY IF EXISTS read_devotionals_insert_today ON public.read_devotionals;
CREATE POLICY read_devotionals_insert_today
ON public.read_devotionals
FOR INSERT
TO authenticated
WITH CHECK (
  user_profile_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.devotionals d
    WHERE d.id = devotional_id
      AND d.published_date = public.get_sp_date()
  )
);

COMMIT;
