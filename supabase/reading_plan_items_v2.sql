-- Ajuste do esquema para planos de leitura baseados em capítulos.
-- Permite armazenar book_name + chapter_number sem depender de verse_id.

alter table public.reading_plan_items
add column if not exists book_name text;

alter table public.reading_plan_items
add column if not exists chapter_number integer;

alter table public.reading_plan_items
drop constraint if exists check_verse_or_devotional_item;

alter table public.reading_plan_items
add constraint check_reading_plan_item_content
check (
  verse_id is not null
  or devotional_id is not null
  or (book_name is not null and chapter_number is not null)
);

create index if not exists reading_plan_items_plan_day_idx
on public.reading_plan_items (reading_plan_id, day_number);
