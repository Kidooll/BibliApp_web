-- Backfill user_reading_plan_item_progress from legacy reading_progress.
-- Safe to run multiple times (idempotent).

begin;

-- 1) Backfill per-user item progress using legacy reading_progress (plan/day only).
-- If you have multiple users for the same plan, add a filter by user_profile_id.
insert into user_reading_plan_item_progress (
  user_reading_plan_progress_id,
  reading_plan_item_id,
  completed_at,
  created_at,
  updated_at
)
with items_by_day as (
  select distinct on (reading_plan_id, day_number)
    id,
    reading_plan_id,
    day_number
  from reading_plan_items
  order by reading_plan_id, day_number, id
)
select
  progress.id,
  items.id,
  legacy.completed_at,
  now(),
  now()
from user_reading_plan_progress progress
join reading_progress legacy
  on legacy.plan_id = progress.reading_plan_id
 and legacy.completed = true
join items_by_day items
  on items.reading_plan_id = progress.reading_plan_id
 and items.day_number = legacy.day_number
left join user_reading_plan_item_progress existing
  on existing.user_reading_plan_progress_id = progress.id
 and existing.reading_plan_item_id = items.id
where existing.id is null
-- and progress.user_profile_id = 'PUT-USER-UUID-HERE'
;

-- 2) Optional: mark plans completed when all days are done.
update user_reading_plan_progress progress
set completed_at = (
  select max(item_progress.completed_at)
  from user_reading_plan_item_progress item_progress
  where item_progress.user_reading_plan_progress_id = progress.id
),
updated_at = now()
from reading_plans plans
where plans.id = progress.reading_plan_id
  and progress.completed_at is null
  and (
    select count(distinct items.day_number)
    from user_reading_plan_item_progress item_progress
    join reading_plan_items items
      on items.id = item_progress.reading_plan_item_id
    where item_progress.user_reading_plan_progress_id = progress.id
  ) >= plans.duration_days;

commit;
